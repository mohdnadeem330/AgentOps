@isTest
public class CalloutToBlobstorageTest {
    @isTest
    public static void testBlobService(){        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGen());
        Test.startTest();
        CalloutToBlobstorage.getSASUrl('aldar/liveAldar/a1dKH000000Co3AYAS/1721388730882.png','LFU');
        List<String> urls = new List<String>{
    'aldar/liveAldar/a1dKH000000Co3AYAS/1721388730882.png'
};
        CalloutToBlobstorage.getBulkSASUrls(urls);
        Test.stopTest();
        
    }
}