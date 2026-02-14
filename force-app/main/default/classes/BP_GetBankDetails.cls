@RestResource(urlMapping='/getBankDetails')
global without sharing class BP_GetBankDetails extends BP_BaseRestResource  {
    static List<String> FieldExceptionCodes = new List<String>{ 'FIELD_CUSTOM_VALIDATION_EXCEPTION', 'FIELD_FILTER_VALIDATION_EXCEPTION', 'INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST'};

    @HttpGet
    global static void fetchBankDetails() {
        RestContextHandler handler = new RestContextHandler(false);
        try {        
            Map<String, String> params = RestContext.request.params;
            BP_GetBankDetails service = new BP_GetBankDetails();
            ApiResponse response = service.processRequest(params, null);
            
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;

            // handler.response.success = true;
            // handler.response.statusCode = 200;
            // handler.response.message = 'Success';
            // handler.response.data = responseData;
           
        }catch(DMLException dmlEx){
            Integer statusCode = 500;
            String errorMessage = dmlEx.getMessage();
            List<String> fieldErrorStrs = new List<String>();
            for(Integer i=0; i<dmlEx.getNumDml(); i++){
                if(FieldExceptionCodes.contains(dmlEx.getDmlStatusCode(i))){
                    fieldErrorStrs.add(dmlEx.getDmlMessage(i));
                }
            }
            if(!fieldErrorStrs.isEmpty()){
                statusCode = 300;
                errorMessage = String.join(fieldErrorStrs, ' ');
            }
        }
        handler.finalize();
    }
public static Map<String, String> getBase64forBankCopy(String agencyId) {
    Map<String, String> result = new Map<String, String>{
        'base64Data' => '', 
        'fileName' => '', 
        'fileExtension' => '',
             'lastModifiedDate' => ''
    };

    List<HexaBPM__SR_Doc__c> listBankCopy = [
        SELECT Id FROM HexaBPM__SR_Doc__c 
        WHERE HexaBPM__Customer__c = :agencyId 
        AND HexaBPM__Document_Name__c = 'Bank Copy' 
        LIMIT 1
    ];
    

    if (!listBankCopy.isEmpty()) {
        List<ContentDocumentLink> listCDL = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :listBankCopy[0].Id 
            ORDER BY SystemModstamp DESC 
            LIMIT 1
        ];
        

        if (!listCDL.isEmpty()) {
            List<ContentDocument> listCD = [
                SELECT Id, Title, FileExtension 
                FROM ContentDocument 
                WHERE Id = :listCDL[0].ContentDocumentId 
                LIMIT 1
            ];
           

            if (!listCD.isEmpty()) {
                List<ContentVersion> listCV = [
                    SELECT VersionData ,LastModifiedDate
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :listCD[0].Id 
                    ORDER BY LastModifiedDate 
                    LIMIT 1
                ];
               

                if (!listCV.isEmpty()) {
                    result.put('base64Data', EncodingUtil.base64Encode(listCV[0].VersionData));
                    result.put('fileName', listCD[0].Title);
                    result.put('fileExtension', listCD[0].FileExtension);
                     result.put('lastModifiedDate', String.valueOf(listCV[0].LastModifiedDate));
             
                }
            }
        }
    }

    
    return result;
}


    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            return new ApiResponse(true, 200,'Account detail are feteched Successfully', getResponseData()); 
        } catch (Exception e) {
            return new ApiResponse(false, 500,'Account detail are fetching failed ' + e.getMessage(), null);
        } 
    }

    public static Map<String, Object> getResponseData() {
    Map<String, Object> responseData = new Map<String, Object>();

    User usr = [SELECT AccountId,
        Account.Name,
        Account.BankCountry__c, 
        Account.BankName__c,
        Account.BranchAddress__c,
        Account.BankAccountNumber__c,
        Account.IBANNumber__c, 
        Account.SwiftCode__c, 
        Account.BeneficiaryName__c, 
        Account.CurrencyIsoCode ,
                  Account.ProposedBankDetailStatus__c 
        FROM User 
        WHERE 
        Id = :UserInfo.getUserId() AND
        isActive = true AND AccountId != null AND 
        Account.RecordType.DeveloperName = 'Broker_Agency'];

    // Fetch bank copy details
    Map<String, String> bankCopyDetails = getBase64forBankCopy(usr.AccountId);
    
    responseData.put('agencyName', usr?.Account?.Name);
    responseData.put('bankCountry', usr?.Account?.BankCountry__c);
    responseData.put('bankName', usr?.Account?.BankName__c);
    responseData.put('bankBranch', usr?.Account?.BranchAddress__c);
    responseData.put('accountNumber', usr?.Account?.BankAccountNumber__c);
    responseData.put('ibanNumber', usr?.Account?.IBANNumber__c);
    responseData.put('swiftCode', usr?.Account?.SwiftCode__c);
    responseData.put('currency', usr?.Account?.CurrencyIsoCode);
    responseData.put('status', usr?.Account?.ProposedBankDetailStatus__c);
    responseData.put('beneficiaryName', usr?.Account?.BeneficiaryName__c);
    
    // Add bank copy details
    responseData.put('bankCopy', bankCopyDetails.get('base64Data'));
    responseData.put('fileName', bankCopyDetails.get('fileName'));
    responseData.put('extension', bankCopyDetails.get('fileExtension'));
        responseData.put('lastModifiedDate', bankCopyDetails.get('lastModifiedDate'));

    return responseData;
}

}