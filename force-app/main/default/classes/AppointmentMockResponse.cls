@isTest
global class AppointmentMockResponse implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        MuleSoftSetting__mdt  appointmentBooking = Utilities.getMuleSoftDetails('appointmentBooking');
        MuleSoftSetting__mdt  appointmentSlot = Utilities.getMuleSoftDetails('appointmentSlot');
        MuleSoftSetting__mdt  appointmentLocation = Utilities.getMuleSoftDetails('appointmentLocation');
        MuleSoftSetting__mdt  appointmentDate = Utilities.getMuleSoftDetails('appointmentDate');
        MuleSoftSetting__mdt  appointmentCancellation = Utilities.getMuleSoftDetails('appointmentCancellation');
        MuleSoftSetting__mdt  appointmentCreateUpdateAgency = Utilities.getMuleSoftDetails('appointmentCreateUpdateAgency');
        //MuleSoftSetting__mdt  appointmentDate = Utilities.getMuleSoftDetails('appointmentDate');
        String responseToReturn='';
        if(req.getEndpoint() == appointmentSlot.SandboxURL__c || req.getEndpoint() == appointmentSlot.ProductionURL__c){
            responseToReturn= '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "6ef9c360-0cf0-11ed-9383-021006dc43c4","results": [{"slotid": 7256,"slot": "09:00 AM - 10:00 AM","PublicBookingAllowed": true,"InternalBookingAllowed": true},{"slotid": 7257,"slot": "10:00 AM - 11:00 AM","PublicBookingAllowed": true,"InternalBookingAllowed": true},{"slotid": 7258,"slot": "11:00 AM - 12:00 PM","PublicBookingAllowed": true,"InternalBookingAllowed": true},{"slotid": 7259,"slot": "12:00 PM - 01:00 PM","PublicBookingAllowed": true,"InternalBookingAllowed": true},{"slotid": 7260,"slot": "01:00 PM - 02:00 PM","PublicBookingAllowed": true,"InternalBookingAllowed": true},{"slotid": 7261,"slot": "02:00 PM - 03:00 PM","PublicBookingAllowed": true,"InternalBookingAllowed": true},{"slotid": 7262,"slot": "03:00 PM - 04:00 PM","PublicBookingAllowed": true,"InternalBookingAllowed": true},{"slotid": 7263,"slot": "04:00 PM - 05:00 PM","PublicBookingAllowed": true,"InternalBookingAllowed": true}]  }';
        }else if(req.getEndpoint() == appointmentDate.SandboxURL__c || req.getEndpoint() == appointmentDate.ProductionURL__c){
            responseToReturn='{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "41296670-0cf0-11ed-9383-021006dc43c4","results": [  "07/27/2022",  "07/28/2022",  "07/29/2022",  "07/30/2022",  "07/31/2022"]  }';
        }else if(req.getEndpoint() == appointmentLocation.SandboxURL__c || req.getEndpoint() == appointmentLocation.ProductionURL__c){
            responseToReturn='{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "ff4d3380-0cef-11ed-9383-021006dc43c4","results": [  {"LocationName": "Abu Dhabi","Emirate": null,"EmiratesId": null,"Longitude": 4576689.0,"Latitude": 6457.0,"MapLocation": "https://bit.ly/3uMV9pl","IsDisable": false,"DisplayName": "Display Abu Dhabi ","DisplayNameArabic": "Display_Abu Dhabi_AR","NationalityName": "United Arab Emirates","TimezoneId": "Arabian Standard Time","Id": 39,"Status": true  },  {"LocationName": "Abu Dhabi center","Emirate": null,"EmiratesId": null,"Longitude": 10.1234,"Latitude": 11.098,"MapLocation": "https://bit.ly/3uMV9pl","IsDisable": false,"DisplayName": "Abu Dhabi Center","DisplayNameArabic": "Abu Dhabi Center","NationalityName": "United Arab Emirates","TimezoneId": "Arabian Standard Time","Id": 40,"Status": true  },  {"LocationName": "Aldar Sales Office","Emirate": null,"EmiratesId": null,"Longitude": null,"Latitude": null,"MapLocation": "https://bit.ly/3uMV9pl","IsDisable": false,"DisplayName": "Aldar Sales Office","DisplayNameArabic": "Aldar Sales Office","NationalityName": "United Arab Emirates","TimezoneId": "Arabian Standard Time","Id": 47,"Status": true  },  {"LocationName": "Dubai","Emirate": null,"EmiratesId": null,"Longitude": null,"Latitude": null,"MapLocation": "https://bit.ly/3uMV9pl","IsDisable": false,"DisplayName": "Display_Dubai","DisplayNameArabic": "Display_DubaiAR","NationalityName": "United Arab Emirates","TimezoneId": "Arabian Standard Time","Id": 38,"Status": true  },  {"LocationName": "Wonderlands","Emirate": null,"EmiratesId": null,"Longitude": 455.66,"Latitude": 3394.45,"MapLocation": "https://bit.ly/3uMV9pl","IsDisable": false,"DisplayName": "Wonderlands","DisplayNameArabic": "Wonderlands","NationalityName": "Australia","TimezoneId": "W. Australia Standard Time","Id": 48,"Status": true  }]  }';
        }else if(req.getEndpoint() == appointmentBooking.SandboxURL__c || req.getEndpoint() == appointmentBooking.ProductionURL__c){
            responseToReturn='{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "9bc0c6a0-0cf0-11ed-9383-021006dc43c4","results": {"slotStartTime": "09:00 AM","slotEndTime": "10:00 AM","LocationNameArabic": "Display_Abu Dhabi_AR","LocationName": "Abu Dhabi","bookingreferencenumber": "6500033","bookingsource": "OnlineBuyer","firstname": "Ahmed","lastname": "almeri","email": "keshri10051@gmail.com","phone": "552417696","nationality": "United Arab Emirates","nationalitycode": "AE","residencystatus": "Resident","ResidencyStatusId": 1,"Location": null,"locationid": "39","projectcode": "Saadiyat Reserve The Dunes","ProjectName": null,"bookingdate": "2022-07-28T00:00:00","bookingslot": "10:00 AM - 11:00 AM","slotid": 7257,"message": "test","categoryid": 1,"categoryname": "Buyer","interactionmethod": null,"phonecountrycode": "971","passportexpirationdate": null,"emiratesid": "123123123123123","residentcityid": 2,"passportnumber": null,"SalesAgentName": null,"BedroomId": null,"ClientType": null}}';
        }else if(req.getEndpoint() == appointmentCancellation.SandboxURL__c || req.getEndpoint() == appointmentCancellation.ProductionURL__c){
            responseToReturn='';
        }else if(req.getEndpoint() == appointmentCreateUpdateAgency.SandboxURL__c || req.getEndpoint() == appointmentCreateUpdateAgency.ProductionURL__c){
            responseToReturn='';
        }else{
            responseToReturn='';
        }
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(responseToReturn);
        res.setStatusCode(200);
        return res;
    }
}