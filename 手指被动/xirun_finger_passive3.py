#requirements:trigger_box.py, xirun_single.py

import asyncio
import logging
import random
from xirun_single import XirunPneumaticFingerClient
import socket
import time

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# List of finger actions and their corresponding indices
finger_indices = {'0': 'rest', '1': 'thumbflex', '2': 'indexflex', '3': 'middleflex', '4': 'ringflex', '5': 'littleflex', '6': 'flex', '7': 'double'}


async def main():
    ################# Set up the socket
    host = '127.0.0.1'  # 本地地址
    port = 65432         # 端口号
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen(1)
    print(f"服务端已启动，等待连接...")

    client_socket, client_address = server_socket.accept()
    print(f"连接来自 {client_address}")


    #################  Set up the XirunPneumaticFingerClient
    strength = 3
    init_params = {"strength": strength}
    client = XirunPneumaticFingerClient(init_params=init_params)

    logger.info("Scanning for devices...")
    result = await client.scan_and_connect()

    # Check if result is valid
    if result is None:
        logger.error("Scan and connect returned None. Check the implementation.")
        return

    # Print all discovered devices
    if "devices" in result:
        logger.info("List of discovered devices:")
        for device in result["devices"]:
            logger.info(f"Device Name: {device.name}, Device Address: {device.address}")
    else:
        logger.warning("No devices found or devices key missing in result.")

    if result.get("is_connected", False):
        logger.info("Device connected successfully!")
        input("Press Enter to start the action...")

    if True:
        ################
        state = '0'
        while True:
            # 接收指令
            data = client_socket.recv(1024)  # 最多接收 1024 字节
            if not data:
                break
            data = data.decode('utf-8')
            print(f"接收到的数据：{data}")

            if data != state:
                # Find the selected finger based on target index
                selected_finger = finger_indices[data]

                # Execute the selected finger flex action
                # logger.info(f"Starting {selected_finger} with strength {strength}...")
                await client.execute(selected_finger)

                # await client.execute("rest")
                await asyncio.sleep(2)  # Hold for the specified duration
            state = data


        logger.info("All fingers have moved 10 times. Action completed!")
    else:
        logger.error("Failed to connect to the device!")

    # Close the connection
    # await client.close()

if __name__ == "__main__":
    asyncio.run(main())