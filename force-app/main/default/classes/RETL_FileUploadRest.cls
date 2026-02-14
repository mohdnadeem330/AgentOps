@RestResource(urlMapping='/FileUpload/*')
global with sharing class RETL_FileUploadRest {
    @HttpPost
    global static void uploadFile() {
        RestRequest req = RestContext.request;
        Blob fileBlob = req.requestBody;
        system.debug('req.headers'+req.headers.get('file-name'));
        String fileName = req.headers.get('file-name');
        String documentType = req.headers.get('document-type');
        String submittingBy = req.headers.get('submitting-by');
        String  networkName = req.headers.get( 'network-name');
        String contactId = req.headers.get( 'contact-id');
        List<Network> tenantPortalNetwork = new List<Network>() ;
        if( submittingBy == 'CommunityUser' && !String.isBlank(networkName)){
            tenantPortalNetwork = [
                SELECT Id, Name, UrlPathPrefix
                FROM Network
                WHERE Name =: networkName // or use criteria to find correct site
                LIMIT 1
            ];
        }
         
        
        ContentVersion cv = new ContentVersion(
            Title = fileName,
            RETL_Document_Type__c =  documentType,
            PathOnClient = '/' + fileName,
            VersionData = fileBlob,
            FirstPublishLocationId = contactId
        );
        if(!Test.isRunningTest() && !tenantPortalNetwork.isEmpty() ) {
            cv.NetworkId = tenantPortalNetwork[0].Id;
        }
        insert cv;
		system.debug('cv.Id'+cv.Id);
        RestContext.response.statusCode = 201;
        RestContext.response.responseBody = Blob.valueOf('{"id":"' + cv.Id + '"}');
    }
}