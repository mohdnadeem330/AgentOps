@IsTest
private class com_ParseSAJson_Test {

    @IsTest
    static void testParseServiceAppointments() {
        // Create a ServiceAppointment instance in memory (no DML needed)
        ServiceAppointment sa = new ServiceAppointment(
            Status        = 'Scheduled',
            Subject       = 'Test Appointment',
            SchedStartTime = System.now(),
            SchedEndTime   = System.now().addHours(2)
        );

        // Serialize as a JSON list
        String saJson = JSON.serialize(new List<ServiceAppointment>{ sa });

        // Build the Invocable input
        com_ParseSAJson.Input input = new com_ParseSAJson.Input();
        input.json = saJson;

        Test.startTest();
        List<com_ParseSAJson.Output> results =
            com_ParseSAJson.parse(new List<com_ParseSAJson.Input>{ input });
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(),
            'One Output object should be returned.');
        System.assertNotEquals(null, results[0].records,
            'Records list should not be null.');
        System.assertEquals(1, results[0].records.size(),
            'One ServiceAppointment should be parsed.');

        ServiceAppointment parsed = results[0].records[0];
        System.assertEquals('Scheduled', parsed.Status,
            'Status should match.');
        System.assertEquals('Test Appointment', parsed.Subject,
            'Subject should match.');
    }

    @IsTest
    static void testParseEmptyList() {
        // Input with an empty JSON array
        com_ParseSAJson.Input input = new com_ParseSAJson.Input();
        input.json = '[]';

        Test.startTest();
        List<com_ParseSAJson.Output> results =
            com_ParseSAJson.parse(new List<com_ParseSAJson.Input>{ input });
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(),
            'Output list should still contain one Output wrapper.');
        System.assertNotEquals(null, results[0].records,
            'Records list should not be null even for empty JSON.');
        System.assertEquals(0, results[0].records.size(),
            'No ServiceAppointments should be parsed from empty JSON.');
    }
}