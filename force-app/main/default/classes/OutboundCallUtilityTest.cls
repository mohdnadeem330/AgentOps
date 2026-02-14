/**
* OutboundCallUtilityTest
*
* Test class for OutboundCallUtility
*/
@isTest
private class OutboundCallUtilityTest{

    //Testing Appointment APIs for lead
     @isTest static void testAppointment() {
         test.startTest();
         Test.setMock(HttpCalloutMock.class, new OutboundCallMockResponse());
         Boolean callingSuccess = false;
          string token = OutboundCallUtility.getAccessToken();
            if(token!=null){
                map<string,string> callingOptionMap =  OutboundCallUtility.getContactLists(token);
                if(callingOptionMap!=null && !callingOptionMap.isEmpty()){
                    String contactListID = callingOptionMap.get(Constants.CONTACTLIST_PAYMENT_REMINDER );
                    callingSuccess = OutboundCallUtility.initiateOutboundCall(token,contactListID,'{}');
                    
                }
            }
           System.AssertEquals(true,callingSuccess);
         test.stopTest();
     }

     @isTest static void testwhatsapp(){
        test.startTest();
         Test.setMock(HttpCalloutMock.class, new OutboundCallMockResponse());
         Boolean callingSuccess = false;
          string token = OutboundCallUtility.getAccessTokenforWhatsapp();
            if(token!=null){
                String flowid = Label.GenesysWhatsappFlowCC;
                Boolean checkW =  OutboundCallUtility.initiateWhatsapp(token, flowid, 'rsrivastava@aldar.com', '971586312767','en');
                /*if(callingOptionMap!=null && !callingOptionMap.isEmpty()){
                    String contactListID = callingOptionMap.get(Constants.CONTACTLIST_PAYMENT_REMINDER );
                    callingSuccess = OutboundCallUtility.initiateOutboundCall(token,contactListID,'{}');
                    
                }*/
                System.AssertEquals(true,checkW);
            }
           
         test.stopTest();
     }
}