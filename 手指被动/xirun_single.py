"""
希润气动手控制类
"""
import asyncio
import logging
import struct

from bleak import BleakClient, BleakError, BleakScanner

# from peripheral.hand.base import PeripheralHandBase

logger = logging.getLogger(__name__)


# class XirunPneumaticFingerClient(PeripheralHandBase):

class XirunPneumaticFingerClient():

    # pylint: disable=line-too-long
    FLEX_FORCES = {
        1: "FF10009500204000010000000000000000000000010000000100010001000100010001000000000000000000000000057805780578057805780000000000000000000000000001AA3A",
        2: "FF1000950020400001000000000000000000000001000000010001000100010001000100000000000000000000000005DC05DC05DC05DC05DC00000000000000000000000000015A29",
        3: "FF1000950020400001000000000000000000000001000000010001000100010001000100000000000000000000000006400640064006400640000000000000000000000000000143E4",
        4: "FF1000950020400001000000000000000000000001000000010001000100010001000100000000000000000000000006A406A406A406A406A40000000000000000000000000001AD2B",
        5: "FF10009500204000010000000000000000000000010000000100010001000100010001000000000000000000000000070807080708070807080000000000000000000000000001FE97",
        6: "FF10009500204000010000000000000000000000010000000100010001000100010001000000000000000000000000073A073A073A073A073A0000000000000000000000000001172C",
        7: "FF10009500204000010000000000000000000000010000000100010001000100010001000000000000000000000000076C076C076C076C076C00000000000000000000000000012FA0",
        8: "FF10009500204000010000000000000000000000010000000100010001000100010001000000000000000000000000079E079E079E079E079E0000000000000000000000000001E73F",
        9: "FF1000950020400001000000000000000000000001000000010001000100010001000100000000000000000000000007D007D007D007D007D000000000000000000000000000015A6F",
    }

    COMMAND_TABLE = {
        "control": "FF06009500014DF8",
        "query": "FF0300B40001D1F2",
        "rest": "FF0600B400039C33",
        "flex": "FF10009500204000010000000000000000000000010000000100010001000100010001000000000000000000000000070807080708070807080000000000000000000000000001FE97",
        "extend": "FF10009500204000010000000000000000000000010000000100010001000100010001000000000000000000000000FD44FD44FD44FD44FD44000000000000000000000000000137B2",
        "double": "FF10009500204000010000000000000000000000010000000100010001000000000000000000000000000000000000070807080708070807080000000000000000000000000001ED16",
        "treble": "FF10009500204000010000000000000000000000010000000100010001000100000000000000000000000000000000070807080708070807080000000000000000000000000001EAAB",
        "thumbflex":    "FF100095002040000100000000000000000000000100000001000100000000000000000000000000000000000000000708070807080708070800000000000000000000000000012F57",  # 拇指
        "indexflex":    "FF100095002040000100000000000000000000000100000001000000010000000000000000000000000000000000000708070807080708070800000000000000000000000000017C46",  # 食指
        "middleflex":   "FF10009500204000010000000000000000000000010000000100000000000100000000000000000000000000000000070807080708070807080000000000000000000000000001B9BA",  # 中指
        "ringflex":     "FF10009500204000010000000000000000000000010000000100000000000000010000000000000000000000000000070807080708070807080000000000000000000000000001B6AB",  # 无名指
        "littleflex":   "FF10009500204000010000000000000000000000010000000100000000000000000001000000000000000000000000070807080708070807080000000000000000000000000001A297",  # 小指
         #"littleflex": "FF10009500204000010000000000000000000000010000000100000000000000000001000000000000000000000000000070807080708070807080000000000000000000000000001A297",  # 小指
    }
    # pylint: enable=line-too-long

    UUID_CMD = "0000c304-0000-1000-8000-00805f9b34fb"
    UUID_NTF = "0000c306-0000-1000-8000-00805f9b34fb"

    def __init__(self, init_params=None):
        self.state = -1
        self.client = None
        self.stop_event = asyncio.Event()

        # basic configs
        self.strength = 5
        if (
            init_params
            and "strength" in init_params
            and init_params["strength"]
        ):
            try:
                strength = int(init_params["strength"])
                if strength in self.FLEX_FORCES:
                    self.strength = strength
                else:
                    logger.warning("Invalid strength value: %s", strength)
            except ValueError:
                logger.warning(
                    "Invalid strength value: %s", init_params["strength"]
                )

    async def init(self):
        # scan and connect forever if stop_event is not set
        while not self.stop_event.is_set():
            if not self.is_connected:
                await self.scan_and_connect()
            await asyncio.sleep(1)

    async def scan_and_connect(self):
        devices = await BleakScanner.discover()
        for device in devices:
            if device.name and "SRH" in device.name:
                logger.info(
                    "Device %s found. Attempting to connect...", device.name
                )
                try:
                    self.client = BleakClient(device.address)
                    ret = await self._connect()
                    if self.is_connected:
                        logger.info("Device %s connected", device.name)
                        return {"is_connected": self.is_connected, "msg": ret}
                except BleakError as e:
                    logger.warning(
                        "Device %s failed to connect: %s", device.name, e
                    )

    @property
    def is_connected(self):
        if self.client is not None:
            return self.client.is_connected
        else:
            return False

    def _notification_handler(self, sender, data):
        """Callback function to handle indications."""
        logger.info("Notification from %s: %s", sender, data)
        u16_value = struct.unpack(">H", data[-4:-2])[0]
        if u16_value == 0:
            self.state = 0
        else:
            self.state = 1
        logger.info("Received data: %d", u16_value)

    async def _connect(self):
        try:
            # connect
            await self.client.connect()

            if self.is_connected:
                await self.client.start_notify(
                    self.UUID_NTF, self._notification_handler
                )
                # turn on control mode
                await self.execute("control")
                while self.state != 0:
                    await self.execute("query")
                    await asyncio.sleep(0.1)
                return 1
            else:
                logger.warning("Connecting failed")
                return 0

        except BleakError as e:
            warning_info = f"pneumatic finger connect failed: {e}"
            logger.warning(warning_info)
            return 0

    async def execute(self, model, wait_time=0):
        if (model not in self.COMMAND_TABLE) and (model != "flex"):
            raise ValueError(f"希润气动手无效模式: {model}")
        if model == "flex":
            command = self.FLEX_FORCES[self.strength]
        else:
            command = self.COMMAND_TABLE[model]
        if wait_time > 0:
            await asyncio.sleep(wait_time)
        await self.client.write_gatt_char(self.UUID_CMD, bytes.fromhex(command))

    def status(self):
        status = {"is_connected": self.is_connected}
        return status

    async def close(self):
        self.stop_event.set()
        if self.is_connected:
            await self.client.disconnect()
        return {"is_connected": self.is_connected}
