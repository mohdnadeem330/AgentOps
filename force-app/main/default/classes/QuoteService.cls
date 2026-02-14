/**********************************************************************************************************************
* Name               : QuoteService                                                         
* Description        : CPQ Premium Parking Service - Invoked from CPQQuoteTriggerHandler
* Created By         : SMAARTT                                                  
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           SMAARTT     14/01/2025      Initial Draft    
******************************************************************************************************************/
public class QuoteService {

    public static final String PREMIUM_PARKING_DOCUMENT_CATEGORY = 'PremiumParkingQuote';

    public static void updateQuoteFields(List<SBQQ__Quote__c> quotes) {
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        Map<Id, String> projectMap = new Map<Id, String>();
        Map<Id, String> buildingMap = new Map<Id, String>();
        Map<Id, Id> accountMap = new Map<Id, Id>();
        Map<Id, String> salesOrderMap = new Map<Id, String>();

        for (SBQQ__Quote__c quote : quotes) {
            if (quote.Building_Section__c != null && quote.Project__c != null && quote.SBQQ__Account__c != null && quote.Sales_Order__c != null) {
                quoteIds.add(quote.Id);
                projectMap.put(quote.Id, quote.Project__c);
                buildingMap.put(quote.Id, quote.Building_Section__c);
                accountMap.put(quote.Id, quote.SBQQ__Account__c);
                salesOrderMap.put(quote.Id, quote.Sales_Order__c);
                accountIds.add(quote.SBQQ__Account__c);
            }
        }

        if (quoteIds.isEmpty()) {
            return;
        }

        // Retrieve and map Account Customer Class
        Map<Id, String> accountCustomerClassMap = new Map<Id, String>();
        for (Account acc : [SELECT Id, CustomerClass__c FROM Account WHERE Id IN :accountIds]) {
            accountCustomerClassMap.put(acc.Id, acc.CustomerClass__c);
        }

        // Retrieve Product Configuration and populate maxParkingMap
        Map<String, Decimal> maxParkingMap = getMaxParkingMap(buildingMap, projectMap, accountCustomerClassMap);

        // Retrieve Asset counts and populate assetCountMap
        Map<String, Integer> assetCountMap = getAssetCountMap(projectMap, buildingMap, accountMap, salesOrderMap);

        // Prepare and update Quotes
        List<SBQQ__Quote__c> quotesToUpdate = prepareQuotesToUpdate(quoteIds, projectMap, buildingMap, accountMap, salesOrderMap, maxParkingMap, assetCountMap, accountCustomerClassMap);
        
        if (!quotesToUpdate.isEmpty()) {
            try {
                update quotesToUpdate;
            } catch (DmlException e) {
                System.debug('DML Exception: ' + e.getMessage());
            }
        }
    }
	@TestVisible
    private static Map<String, Decimal> getMaxParkingMap(
        Map<Id, String> buildingMap, Map<Id, String> projectMap, Map<Id, String> accountCustomerClassMap) {

        Map<String, Decimal> maxParkingMap = new Map<String, Decimal>();
        List<Product_Configuraton__c> configs = [
            SELECT Building__c, Project__c, Customer_Class__c, Max_Parking__c
            FROM Product_Configuraton__c
            WHERE RecordType.DeveloperName = 'Max_Parking'
              AND Building__c IN :buildingMap.values()
              AND Project__c IN :projectMap.values()
              AND Customer_Class__c IN :accountCustomerClassMap.values()
        ];

        for (Product_Configuraton__c config : configs) {
            String key = config.Building__c + ':' + config.Project__c + ':' + config.Customer_Class__c;
            if (!maxParkingMap.containsKey(key) || config.Max_Parking__c > maxParkingMap.get(key)) {
                maxParkingMap.put(key, config.Max_Parking__c);
            }
        }

        return maxParkingMap;
    }
    
	@TestVisible
    private static Map<String, Integer> getAssetCountMap(
        Map<Id, String> projectMap, Map<Id, String> buildingMap, Map<Id, Id> accountMap, Map<Id, String> salesOrderMap) {

        Map<String, Integer> assetCountMap = new Map<String, Integer>();
        List<AggregateResult> assetCounts = [
            SELECT Project__c, Building__c, Reserved_Account__c, Sales_Order__c, COUNT(Id) totalCount
            FROM Asset
            WHERE Project__c IN :projectMap.values()
              AND Building__c IN :buildingMap.values()
              AND Reserved_Account__c IN :accountMap.values()
              AND Sales_Order__c IN :salesOrderMap.values()
              AND RecordTypeName__c='Premium_Parking'
            GROUP BY Project__c, Building__c, Reserved_Account__c, Sales_Order__c
        ];

        for (AggregateResult ar : assetCounts) {
            String key = ar.get('Project__c') + ':' + ar.get('Building__c') + ':' + ar.get('Reserved_Account__c') + ':' + ar.get('Sales_Order__c');
            assetCountMap.put(key, (Integer) ar.get('totalCount'));
        }

        return assetCountMap;
    }

    public static List<SBQQ__Quote__c> prepareQuotesToUpdate(
        Set<Id> quoteIds, Map<Id, String> projectMap, Map<Id, String> buildingMap, Map<Id, Id> accountMap,
        Map<Id, String> salesOrderMap, Map<String, Decimal> maxParkingMap, Map<String, Integer> assetCountMap, 
        Map<Id, String> accountCustomerClassMap) {

        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        Map<String, String> quoteIdAssetRefIdMap = new Map<String, String>();
        for (SBQQ__Quote__c quote : [SELECT Id, Max_Parking__c, AssetCount__c, Parking_Ref_ID__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds]) {
            String key = projectMap.get(quote.Id) + ':' + buildingMap.get(quote.Id) + ':' + accountMap.get(quote.Id) + ':' + salesOrderMap.get(quote.Id);
            String maxParkingKey = buildingMap.get(quote.Id) + ':' + projectMap.get(quote.Id) + ':' + accountCustomerClassMap.get(accountMap.get(quote.Id));

            if (maxParkingMap.containsKey(maxParkingKey)) {
                quote.Max_Parking__c = maxParkingMap.get(maxParkingKey);
            }
            if (assetCountMap.containsKey(key)) {
                quote.AssetCount__c = assetCountMap.get(key);
            }
			quoteIdAssetRefIdMap.put(quote.Id, quote.Parking_Ref_ID__c);
            quotesToUpdate.add(quote);
        }
        List<Asset> assetList = [SELECT Id, Ref_ID__c  FROM Asset WHERE Ref_Id__c IN: quoteIdAssetRefIdMap.values()];
            Map<String, String> assMap = new Map<String, String>();
            for(Asset thisAsset : assetList){
                assMap.put(thisAsset.Ref_Id__c, thisAsset.Id);
            }
            for(SBQQ__Quote__c quote : quotesToUpdate){
                String refId = quoteIdAssetRefIdMap.get(quote.Id);
                String assetId = assMap.get(refId);
                quote.ParkingAsset__c = assetId;
            }
        return quotesToUpdate;
    }

    public static void generateDocumentPlaceholders(List<Order> orderRecords){
        List<Document__c> documentListToInsert = new List<Document__c>();
        Map<String, Id> documentRecordTypeMap = new Map<String, Id>();
        Map<string, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{PREMIUM_PARKING_DOCUMENT_CATEGORY});
        Map<Id, Order> orderIdToRecMap = new map<Id, Order>(orderRecords);
        System.debug('####documentMap: '+documentMap);
        if(!documentMap.isEmpty() && !orderIdToRecMap.isEmpty()){
            //get Existing Documents
            Map<String, Document__c> existingDocMap = new Map<String, Document__c>();
            for(Document__c tempDoc : [SELECT Id, DocumentType__c, Quote__c, Order__c
                                        FROM Document__c 
                                        WHERE Order__c IN :orderIdToRecMap.keySet()]){   
                existingDocMap.put(tempDoc.Order__c+tempDoc.DocumentType__c,tempDoc);
            }

            System.debug('####existingDocMap: '+existingDocMap);

            for(Order orderRecord : orderRecords){
                    String documentTypeToProcess; 
                    List<DocumentPlaceHolder__mdt> documentsToProcess = new List<DocumentPlaceHolder__mdt>();
                    
                    documentsToProcess.addAll(documentMap.get(PREMIUM_PARKING_DOCUMENT_CATEGORY));

                    for(DocumentPlaceHolder__mdt tempMetaRec : documentsToProcess){

                        String recordTypeID = null;
                    
                        if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                            if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                                documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                            }
                            recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                        }
                        
                        if(!existingDocMap.containsKey(orderRecord.Id + tempMetaRec.DocumentType__c)){
                            // Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'',quoteRecord.Id,recordTypeID);
                            Document__c documentRecord = new Document__c();
                            documentRecord.Order__c = orderRecord.Id;
                            documentRecord.DocumentType__c = tempMetaRec.DocumentType__c;
                            documentRecord.RecordTypeId = recordTypeID;
                            documentRecord.SendForESign__c= tempMetaRec.eSignRequired__c;
                            documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                            documentRecord.EligibleForeSign__c=tempMetaRec.EligibleForeSign__c;
                            documentRecord.DocgenPackageId__c = tempMetaRec.DocgenPackageName__c;
                            documentRecord.DeliveryOptionId__c = tempMetaRec.DeliveryOption__c;
                            documentRecord.Account__c = orderRecord.AccountId;
                            
                            documentListToInsert.add(documentRecord); 
                            existingDocMap.put(orderRecord.Id + tempMetaRec.DocumentType__c,documentRecord);       
                        }
                    }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;
            
          //Added by Harsh@Aldar 20/02/2025 Static Quote Doc
          //handleStaticDocumentUpload(documentListToInsert);
        } 
    }
    
    //Added By Harsh@Aldar 20/02/2025 - For attaching a static quote document to reduce delay in doc gen from nintex
    /*private static void handleStaticDocumentUpload(List<Document__c> documentList){
        system.debug('#### ENTRY ONE handleStaticDocumentUpload: '+documentList);
        List<Id> documentsIdToUpdate = new List<Id>();
        // Loop through the list of Document__c records
        for (Document__c doc : documentList) {
            // Check if the DocumentType__c is 'Premium Parking Quote Doc'
            if (doc.DocumentType__c == 'Premium Parking Quote Doc') {
                documentsIdToUpdate.add(doc.Id);
            }
        }
        
        system.debug('#### ENTRY TWO documentsIdToUpdate: '+documentsIdToUpdate);
        
        for(Document__c thisDoc : [SELECT Id, Quote__c, Quote__r.Parking_Type__c 
                                   FROM Document__c 
                                   WHERE Id IN: documentsIdToUpdate 
                                   AND Quote__c != null 
                                   AND Quote__r.Parking_Type__c != null]){
            uploadStaticDocument(thisDoc.Id, thisDoc.Quote__r.Parking_Type__c);
        }
    }
    
    //Added By Harsh@Aldar 20/02/2025 - For attaching a static quote document to reduce delay in doc gen from nintex
    public static void uploadStaticDocument(String documentPlaceholderId, String quoteParkingType) {
        system.debug('#### '+documentPlaceholderId+'------'+quoteParkingType);
        // Check if the quoteParkingType is valid
        if (String.isBlank(quoteParkingType)) {
            throw new IllegalArgumentException('quoteParkingType cannot be blank');
        }

        // Declare a Blob variable to hold the PDF content
        Blob fileContent;

        // Select the correct static resource based on the quoteParkingType
        if (quoteParkingType == 'Enclosed Garage') {
            // Fetch the Enclosed Garage PDF from the static resource
            fileContent = getStaticResourceFile('PremPark_EnclosedGarageDoc');
        } else if (quoteParkingType == 'Parking Bay') {
            // Fetch the Parking Bay PDF from the static resource
            fileContent = getStaticResourceFile('PremPark_ParkingBayDoc');
        }

        if (fileContent == null) {
            return;
        }

        // Create the ContentVersion (file) record
        ContentVersion newContentVersion = new ContentVersion(
            Title = 'Parking Document '+quoteParkingType + '.pdf',
            PathOnClient = 'Parking Document '+quoteParkingType + '.pdf',
            VersionData = fileContent,
            IsMajorVersion = true
        );

        // Insert the ContentVersion (this will create the file in Salesforce)
        insert newContentVersion;
        
        ContentVersion insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newContentVersion.Id LIMIT 1];
        
        // Now we need to associate the ContentVersion with the Document__c record (using ContentDocumentLink)
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = insertedContentVersion.ContentDocumentId,
            LinkedEntityId = documentPlaceholderId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        // Insert the link to associate the file with the Document__c record
        insert docLink;

        // Now update the Document__c record to set the status as 'Uploaded'
        Document__c docRecord = new Document__c();
        docRecord.Id = documentPlaceholderId;
        docRecord.Status__c = 'Uploaded';
        update docRecord;
    }
    
	//Added By Harsh@Aldar 20/02/2025 - For attaching a static quote document to reduce delay in doc gen from nintex
    // Helper method to get file content from the static resource
    @TestVisible
    private static Blob getStaticResourceFile(String resourceName) {
        // Retrieve the static resource by name
        StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = :resourceName LIMIT 1];
        
        if (resource != null) {
            return resource.Body;
        }
        
        return null;
    }*/
    
}