@isTest
private class BitlyShortenURLTest {
    
    @isTest static  void bitlyCallout() {

        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.OwnerId = UserInfo.getUserId();

        BitlyShortenURL.BitlyRequest bitlyRequest = new BitlyShortenURL.BitlyRequest();
        bitlyRequest.url = 'https://wa.me/+97128107696?text=Hello, I’m interested in and I would like to know more about the project, my reference number is 853495';
        bitlyRequest.smsBody = 'SMS Text Test';
        bitlyRequest.destination = '962787120342';
        bitlyRequest.lead = leadRec;

        List<BitlyShortenURL.BitlyRequest> lst = new List<BitlyShortenURL.BitlyRequest>();
        lst.add(bitlyRequest);
        database.insert(bitlyRequest.lead,false);

        Test.startTest();
        BitlyShortenURL.shortenURL(lst);
        Test.stopTest();

        // Fail Mock
        mock.setStaticResource('GetEmailValidationFail');
        Test.setMock(HttpCalloutMock.class, mock);

        BitlyShortenURL.shortenURL(lst);

        bitlyRequest.lead = null;
        BitlyShortenURL.shortenURL(new List<BitlyShortenURL.BitlyRequest>{bitlyRequest});
        
        
    }
    
    @isTest static  void bitlyCalloutHelper() {
        
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        
        // Success Mock
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.OwnerId = UserInfo.getUserId();
        
        BitlyShortenURL.BitlyRequest bitlyRequest = new BitlyShortenURL.BitlyRequest();
        bitlyRequest.url = 'https://wa.me/+97128107696?text=Hello, I’m interested in and I would like to know more about the project, my reference number is 853495';
        bitlyRequest.smsBody = 'SMS Text Test';
        bitlyRequest.destination = '962787120342';
        bitlyRequest.lead = leadRec;
        Test.startTest();
        BitlyShortenURL.shortenURLHelper('https://wa.me/+97128107696?text=Hello');
        Test.stopTest();
        /*List<BitlyShortenURL.BitlyRequest> lst = new List<BitlyShortenURL.BitlyRequest>();
        lst.add(bitlyRequest);
        database.insert(bitlyRequest.lead,false);
        
        Test.startTest();
        BitlyShortenURL.shortenURL(lst);
        Test.stopTest();
        
        // Fail Mock
        mock.setStaticResource('GetEmailValidationFail');
        Test.setMock(HttpCalloutMock.class, mock);
        
        BitlyShortenURL.shortenURL(lst);
        
        bitlyRequest.lead = null;
        BitlyShortenURL.shortenURL(new List<BitlyShortenURL.BitlyRequest>{bitlyRequest});
        */
        
    }
    
     @isTest static  void bitlySMSCallout() {

        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        BitlyShortenURL.callSMSAPI(null,null,null,null,null,false);
    }
}