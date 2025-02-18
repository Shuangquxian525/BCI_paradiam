#requirements:trigger_box.py, xirun_single.py

import asyncio
import logging
import random
from xirun_single import XirunPneumaticFingerClient
from trigger_box import TriggerNeuracle

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def main():
    # Set strength (range: 1 to 9)
    strength = 3  # You can change this value as needed
    init_params = {"strength": strength}
    
    # Set the duration for flex and rest actions
    flex_duration = 2.5  # Duration for flex action in seconds
    rest_duration = 2.5  # Duration for rest action in seconds

    # Initialize the client with strength setting
    client = XirunPneumaticFingerClient(init_params=init_params)

    # Initialize the trigger box
    # trigger = TriggerNeuracle(port="COM7")  # Replace "COM7" with the correct port for your setup

    # Connect to the device
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

        # List of finger actions and their corresponding indices
        finger_actions = ["thumbflex", "indexflex", "middleflex", "ringflex", "littleflex"]
        finger_indices = {
            "thumbflex": 0,
            "indexflex": 1,
            "middleflex": 2,
            "ringflex": 3,
            "littleflex": 4
        }

        # Generate targetlist with random order of fingers (10 rounds)
        Aim = [0, 1, 2, 3, 4]
        # Aim =[4]
        targetlist = []
        for _ in range(10):
            random.shuffle(Aim)
            targetlist += Aim.copy()

        # Track the number of times each finger has moved
        finger_counts = {finger: 0 for finger in finger_actions}

        # Loop through targetlist and execute actions
        for F_ind, target in enumerate(targetlist):
            # Find the selected finger based on target index
            selected_finger = list(finger_indices.keys())[list(finger_indices.values()).index(target)]

            # Execute the selected finger flex action
            logger.info(f"Starting {selected_finger} with strength {strength}...")
            trigger_value = 0x01 + target  # Generate trigger value
            # trigger.send_trigger(trigger_value)  # Send trigger for flex
            await client.execute(selected_finger)
            await asyncio.sleep(flex_duration)  # Hold for the specified duration

            # Execute rest action
            logger.info("Starting rest...")
            # trigger.send_trigger(0x00)  # Send trigger for rest
            await client.execute("rest")
            await asyncio.sleep(rest_duration)  # Hold for the specified duration

            # Increment the count for the selected finger
            finger_counts[selected_finger] += 1
            logger.info(f"{selected_finger} has moved {finger_counts[selected_finger]} times.")

        logger.info("All fingers have moved 10 times. Action completed!")
    else:
        logger.error("Failed to connect to the device!")

    # Close the connection
    await client.close()

if __name__ == "__main__":
    asyncio.run(main())