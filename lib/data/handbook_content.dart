/// NEMT Driver Handbook Content
/// Contains policies and guidelines for DriveMe/YazTrans drivers.

class HandbookSection {
  final String title;
  final String content;

  const HandbookSection({
    required this.title,
    required this.content,
  });
}

class HandbookContent {
  static const List<HandbookSection> sections = [
    HandbookSection(
      title: 'Introduction',
      content: '''
Welcome to the DriveMe/YazTrans Driver Team! 
As an NEMT (Non-Emergency Medical Transportation) driver, you play a critical role in ensuring our members reach their medical appointments safely and on time. This handbook outlines the essential policies and procedures you must follow.
''',
    ),
    HandbookSection(
      title: 'Safety First Policies',
      content: '''
• **Defensive Driving**: Always practice defensive driving. Monitor your speed, maintain safe following distances, and be aware of your surroundings.
• **Vehicle Inspection**: Complete a pre-trip inspection before every shift. Check tires, lights, brakes, and fluid levels. Report any issues immediately.
• **Passenger Securement**: Ensure all passengers are properly secured. Use seatbelts for all passengers. For wheelchair transport, ensure the wheelchair is strictly secured using the 4-point tie-down system and the passenger lap/shoulder belt is fastened.
• **No Distractions**: Use of mobile phones for personal calls or texting while driving is strictly prohibited. Use the driver app only when safe to do so.
''',
    ),
    HandbookSection(
      title: 'Accident Reporting Procedures',
      content: '''
In the event of an accident, follow these steps immediately:

1. **Stop Immediately**: Ensure the vehicle is in a safe location if possible.
2. **Check for Injuries**: Assess yourself and your passengers. Call 911 immediately if there are any injuries.
3. **Notify Authorities**: Contact the police for any accident involving injuries or significant property damage. obtain a police report number.
4. **Call the Hotline**: Use the "Report an Accident" button in this app to call the Driver Hotline immediately.
5. **Collect Information**: Exchange information with other drivers (Name, Insurance, License Plate). Take photos of the scene and damage if safe to do so.
6. **Do Not Admit Fault**: Stick to the facts when speaking with police or other parties.
''',
    ),
    HandbookSection(
      title: 'Passenger Handling & Service',
      content: '''
• **Door-to-Door Service**: We provide door-to-door service. Assist passengers from the door of their pickup location to the door of their destination.
• **Professionalism**: Treat all passengers with dignity and respect. Wear your uniform or badge if required.
• **On-Time Performance**: Arrive at pickup locations 15 minutes prior to the scheduled time. If you are running late, notify dispatch immediately.
• **Cancellations/No-Shows**: If a passenger is not at the pickup location, wait at least 10 minutes and contact dispatch before marking as a No-Show.
''',
    ),
    HandbookSection(
      title: 'Emergency Procedures',
      content: '''
• **Medical Emergencies**: If a passenger experiences a medical emergency during transport, pull over safely and call 911 immediately. Then notify dispatch.
• **Vehicle Breakdown**: Pull over to a safe area. Activate hazard lights. Contact the Driver Hotline for roadside assistance or a replacement vehicle.
''',
    ),
    HandbookSection(
      title: 'Compliance & Ethics',
      content: '''
• **Zero Tolerance**: We have a zero-tolerance policy for alcohol or drug use while on duty.
• **Fraud Prevention**: accurately report all trip data (mileage, times). Falsifying records is grounds for immediate termination.
• **Privacy (HIPAA)**: Protect member confidentiality. Do not discuss member medical conditions or personal information with others.
''',
    ),
  ];
}
