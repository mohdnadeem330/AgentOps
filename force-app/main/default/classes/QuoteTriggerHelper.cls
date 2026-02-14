public class QuoteTriggerHelper {
    public static void checkAssetAvailabilityForLOI(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {
        Set<Id> quotesToCheck = new Set<Id>();
        for (Quote newQuote : newQuotes) {
            Quote oldQuote = oldQuoteMap.get(newQuote.Id);
            if (newQuote.Status == 'LOI Signed' && oldQuote.Status != 'LOI Signed') {
                quotesToCheck.add(newQuote.Id);
            }
        }

        if (quotesToCheck.isEmpty()) {
            return;
        }

        Map<Id, List<QuoteLineItem>> quoteToQLIs = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem qli : [SELECT Id, QuoteId, Asset__r.Name,Asset__r.Status FROM QuoteLineItem WHERE QuoteId IN :quotesToCheck]) {
            if (!quoteToQLIs.containsKey(qli.QuoteId)) {
                quoteToQLIs.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            quoteToQLIs.get(qli.QuoteId).add(qli);
        }

        for (Quote quote : newQuotes) {
            if (quotesToCheck.contains(quote.Id)) {
                List<QuoteLineItem> qlis = quoteToQLIs.get(quote.Id);
                if (qlis != null) {
                    List<String> unavailableAssetNames = new List<String>();
                    for (QuoteLineItem qli : qlis) {
                        if (qli.Asset__r.Status != 'Available') {
                            unavailableAssetNames.add(qli.Asset__r.Name);
                        }
                    }
                    if (!unavailableAssetNames.isEmpty()) {
                        quote.addError('Cannot set status to LOI Signed. Some assets are not available for lease. Unavailable asset names: ' + String.join(unavailableAssetNames, ', '));
                    }
                }
            }
        }
    }

    public static void updateLOISigningDate(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {
        Set<Id> quotesIdsForLOI = new Set<Id>();
        Set<Id> quotesIdsForSignedLeaseAgreement = new Set<Id>();
        for (Quote newQuote : newQuotes) {
            Quote oldQuote = oldQuoteMap.get(newQuote.Id);
            if (newQuote.Status == 'LOI Signed' && oldQuote.Status != 'LOI Signed') {
                newQuote.LOI_Signing_Date__c = Date.today();
                quotesIdsForLOI.add(newQuote.Id);
            } else if (newQuote.Status == 'Lease Agreement Signed' && oldQuote.Status != 'Lease Agreement Signed') {
                quotesIdsForSignedLeaseAgreement.add(newQuote.Id);
            }
        }

        // Validate LOI documents
        if(!quotesIdsForLOI.isEmpty()) {
            List<String> loiDocTypes = new List<String>{'Signed LOI Agreement'};
             for(Id quoteId : quotesIdsForLOI) {

                    String incompleteDocMessage = validateDocuments(quoteId, 'Logistics_Quote__c', loiDocTypes);

                    if(incompleteDocMessage != null && incompleteDocMessage != '') {

                        for(Quote quote : newQuotes) {

                            if(quote.Id == quoteId) {

                                quote.addError('Please upload required documents before changing status to LOI Signed: ' + incompleteDocMessage);

                            }
                    }
                }
            }
        }

        // Validate Lease Agreement documents 
        if(!quotesIdsForSignedLeaseAgreement.isEmpty()) {
            List<String> leaseDocTypes = new List<String>{'Signed Lease Agreement'};
             for(Id quoteId : quotesIdsForSignedLeaseAgreement) {

                    String incompleteDocMessage = validateDocuments(quoteId, 'Logistics_Quote__c', leaseDocTypes);

                    if(incompleteDocMessage != null && incompleteDocMessage != '') {

                        for(Quote quote : newQuotes) {

                            if(quote.Id == quoteId) {

                                quote.addError('Please upload required documents before changing status to Lease Agreement Signed: ' + incompleteDocMessage);

                            }
                    }
                }
            }
        }
    }

    public static void updateAssetStatusForLOI(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {
        Set<Id> quotesToUpdate = new Set<Id>();
        for (Quote newQuote : newQuotes) {
            Quote oldQuote = oldQuoteMap.get(newQuote.Id);
            if (newQuote.Status == 'LOI Signed' && oldQuote.Status != 'LOI Signed') {
                quotesToUpdate.add(newQuote.Id);
            }
        }

        if (quotesToUpdate.isEmpty()) {
            return;
        }

        List<QuoteLineItem> qlisToUpdate = [SELECT Id, Asset__c FROM QuoteLineItem WHERE QuoteId IN :quotesToUpdate AND Asset__c != null];
        List<Asset> assetsToUpdate = new List<Asset>();

        for (QuoteLineItem qli : qlisToUpdate) {
            assetsToUpdate.add(new Asset(Id = qli.Asset__c, Status = 'Reserved'));
        }

        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
    }

    
    public static void createQuoteDocuments(List<Quote> newQuotes) {
        Id logisticsRecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Logistics').getRecordTypeId();
        List<Document__c> documentListToInsert = new List<Document__c>();
          Map<String, ID> documentRecordTypeMap = new Map<String, ID>();

        Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{

            'Logistics'

                });

        

        if (!documentMap.isEmpty()) {

            for (Quote QuoteRecord : newQuotes) {

                String documentTypeToProcess;

                List<DocumentPlaceHolder__mdt> documentsToProcess = new List<DocumentPlaceHolder__mdt>();

                

                if (QuoteRecord.RecordTypeId == logisticsRecordTypeId) {

                    documentTypeToProcess = 'Logistics';

                }

                if (documentTypeToProcess != null && documentMap.containsKey(documentTypeToProcess)) {

                    documentsToProcess.addAll(documentMap.get(documentTypeToProcess));

                }

                

                for (DocumentPlaceHolder__mdt tempMetaRec : documentsToProcess) {

                    String recordTypeID = null;

                    

                    if (tempMetaRec.RecordTypeDeveloperName__c != null) {

                        if (!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)) {

                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, 

                                                      Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());

                        }

                        recordTypeID = documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);

                    }

                    

                    Document__c documentRecord = New Document__c(); 

                    documentRecord.RecordtypeId= recordTypeID;

                    documentRecord.DocumentType__c = tempMetaRec.DocumentType__c;

                    documentRecord.Logistics_Quote__c = QuoteRecord.Id;

                    documentRecord.SendForESign__c = tempMetaRec.eSignRequired__c;

                    documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;

                    documentRecord.EligibleForeSign__c = tempMetaRec.EligibleForeSign__c;

                    

                    documentListToInsert.add(documentRecord);      

                }

            }

        }

        

        if (!documentListToInsert.isEmpty()) {

            insert documentListToInsert;  

        } 

    }

    

    private static String validateDocuments(Id parentId, String relationshipName, List<String> docTypesToValidate) {
        List<String> missingsDocTypes = new List<String>();
        if( parentId != null && docTypesToValidate != null){
            String query = 'SELECT Id, DocumentType__c, (SELECT Id FROM ContentDocumentLinks) FROM Document__c'
                         + ' WHERE '+ relationshipName + ' =: parentId'
                         + (!docTypesToValidate.isEmpty() ? ' AND DocumentType__c IN: docTypesToValidate' : '') ;
            for( Document__c doc: Database.query(query) ){
                if( doc.ContentDocumentLinks == null || doc.ContentDocumentLinks.isEmpty() ){
                    missingsDocTypes.add(doc.DocumentType__c);
                }
            }
        }
        return String.join(missingsDocTypes, ', ');
    }
    
    

    // ADDED BY CLOUDZLAB START

    public static void syncSAP(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {



        // Added to bypass the error in guest user

        String userType = UserInfo.getUserType();



        if (newQuotes.isEmpty() || userType == 'Guest' || userType == 'Guest User') return;

        

        List<User> iusers = [

    SELECT Id 

    FROM User 

    WHERE Username = 'iuser@clodzlab.com.leasing' 

    LIMIT 1

];



Id integrationUserId;

if (!iusers.isEmpty()) {

    integrationUserId = iusers[0].Id;

}



        

        List<Quote> quotesToUpdate = new List<Quote>();

        

        for (Quote newQuote : newQuotes) {

            Quote oldQuote = oldQuoteMap.get(newQuote.Id);

            

            if (UserInfo.getUserId() == integrationUserId) {

                continue;

            }

            

            Boolean markForSync = false;

            

            if (newQuote.ECSS_OfferStatus__c != oldQuote.ECSS_OfferStatus__c) {

                if (new Set<String>{'Released','Cancelled'}

                    .contains(newQuote.ECSS_OfferStatus__c)) {

                        markForSync = true;

                    }

            }

            

            if (markForSync) {

                quotesToUpdate.add(new Quote(

                    Id = newQuote.Id,

                    ECSS_SAPSync__c = true

                ));

            }

        }

        

        // Added to bypass the error in guest user (to be changed)

        // Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];

        // if (p.Name == 'Client Offer Letter Response Profile') {

        //     return;

        // }

        

        if (!quotesToUpdate.isEmpty()) {

            update quotesToUpdate;

        }

    }

    

  /* public static void syncSAPOnInsert(List<Quote> newQuotes) {

        Id integrationUserId = [

            SELECT Id 

            FROM User 

            WHERE Username = 'iuser@clodzlab.com.leasing'

            LIMIT 1

        ].Id;

        

        List<Quote> quotesToUpdate = new List<Quote>();

        

        for (Quote newQuote : newQuotes) {

            if (UserInfo.getUserId() != integrationUserId) {

                quotesToUpdate.add(new Quote(

                    Id = newQuote.Id,

                    ECSS_SAPSync__c = true

                ));

            }

        }

        

        if (!quotesToUpdate.isEmpty()) {

            update quotesToUpdate;

        }

    } */

public static void publishOfferEvents(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {

    List<Offer_Event__e> events = new List<Offer_Event__e>();



    for (Quote newQuote : newQuotes) {

        Quote oldQuote = oldQuoteMap != null && oldQuoteMap.containsKey(newQuote.Id) 

            ? oldQuoteMap.get(newQuote.Id) 

            : null;

		System.debug('Q'+newQuote.ECSS_OfferStatus__c+'--'+oldQuote.ECSS_OfferStatus__c);

        if (

            newQuote.ECSS_OfferStatus__c != null &&

            (newQuote.ECSS_OfferStatus__c == 'Released' || newQuote.ECSS_OfferStatus__c == 'Cancelled') &&

            (oldQuote == null || oldQuote.ECSS_OfferStatus__c != newQuote.ECSS_OfferStatus__c)

        ) {

            Offer_Event__e eventRecord = new Offer_Event__e();

            eventRecord.ECSS_OfferType__c                  = newQuote.ECSS_OfferType__c;

            eventRecord.ECSS_CompanyCode__c                = newQuote.ECSS_CompanyCode__c;

            eventRecord.Name__c                            = newQuote.Name;

            eventRecord.ECSS_ReserveToDate__c              = newQuote.ECSS_Commencement_date__c;

            eventRecord.ECSS_TenancyLaw__c                 = newQuote.ECSS_TenancyLaw__c;

            eventRecord.ECSS_OfferTermStartDate__c         = Date.today();

            eventRecord.ECSS_OfferTermEndDate__c           = Date.today().addDays(1);

            eventRecord.ECSS_CashFlowFromDate__c           = newQuote.ECSS_CashFlowFromDate__c;

            eventRecord.ECSS_ProspectApplicantAccountBP__c = newQuote.ECSS_ProspectApplicantAccountBP__c;

            eventRecord.ECSS_SignatoryRoleZSIGNTBP__c      = newQuote.ECSS_SignatoryRoleZSIGNTBP__c;

            //eventRecord.ECSS_RentAmount__c                 = newQuote.ECSS_RentAmount__c;

            //eventRecord.ECSS_SD__c                         = newQuote.ECSS_SD__c;

            //eventRecord.ECSS_TAF__c                        = newQuote.ECSS_TAF__c;

            //eventRecord.ECSS_SDAmount__c                   = newQuote.ECSS_SDAmount__c;

            //eventRecord.ECSS_TAFAmount__c                  = newQuote.ECSS_TAFAmount__c;

            eventRecord.ECSS_NoOfCheques__c                = newQuote.ECSS_Payment_terms__c;

            //eventRecord.ECSS_OfferLeadOrigin__c            = newQuote.ECSS_OfferLeadOrigin__c;

            eventRecord.ECSS_OfferStatus__c                = newQuote.ECSS_OfferStatus__c;

            eventRecord.ECSS_BrokerBP__c                   = newQuote.ECSS_BrokerBP__c;

            eventRecord.ECSS_BrokerPayBy__c                = newQuote.ECSS_BrokerPayBy__c;

            eventRecord.ECSS_QuoteId__c                    = newQuote.Id;

            eventRecord.ECSS_SapOfferNo__c                 = newQuote.ECSS_SAPExternalId__c;

            //eventRecord.ECSS_SAPReferenceNumber__c         = newQuote.ECSS_SAPExternalId__c;

            eventRecord.ECSS_Amount__c                     = newQuote.TotalPrice;

            eventRecord.ECSS_SAPSync__c                    = newQuote.ECSS_SAPSync__c;

            eventRecord.ECSS_SAPSyncStatus__c              = newQuote.ECSS_SAPSyncStatus__c;

            eventRecord.ECSS_OwnerCommission__c            = newQuote.ECSS_OwnerCommission__c;

            eventRecord.ECSS_SupplimentaryTexts__c         = newQuote.Name;

            



            events.add(eventRecord);

        }

    }



    if (!events.isEmpty()) {

        Database.SaveResult[] results = EventBus.publish(events);

        for (Database.SaveResult sr : results) {

            System.debug('Offer_Event__e published => Success: ' + sr.isSuccess() + ', Id: ' + sr.getId());

            if (!sr.isSuccess()) {

                for (Database.Error err : sr.getErrors()) {

                    System.debug('Error: ' + err.getMessage());

                }

            }

        }

    }

}



    public static void publishAssetEvents(List<Quote> newQuotes, Map<Id, Quote> oldQuotes) {

      /*  System.debug('publishAssetEvents Entered');

        

        List<Asset_Event__e> events = new List<Asset_Event__e>();

        

        

        Set<Id> quoteIds = new Set<Id>();

        for (Quote q : newQuotes) {

            Quote oldQ = oldQuotes.get(q.Id);

            

            if (q.Status == 'Booked' && (oldQ == null || oldQ.Status != 'Booked')) {

                quoteIds.add(q.Id);

            }

        }

        

        if (!quoteIds.isEmpty()) {

            system.debug('QIDa'+quoteIds);

            List<QuoteLineItem> qlis = [

    SELECT 

        Id,

        Asset__c,

        QuoteId,

        Asset__r.External_Id__c,

        Asset__r.ECSS_Availability_Date__c,

        Asset__r.ECSS_Features_Amenities__c,

        Asset__r.ECSS_Listing_Type__c,

        Asset__r.ECSS_Number_of_Cheques__c,

        Asset__r.ECSS_Number_of_Baths__c,

        Asset__r.Name,

        Asset__r.Owner.Email,

        Asset__r.Owner.Phone,

        Asset__r.ECSS_Plot_Size__c,

        Asset__r.ECSS_Property_Size_Built_up_area__c,

        Asset__r.ECSS_Title_Deed_Number__c,

        Asset__r.ECSS_Trakheesi_Permit_Number__c,

        Asset__r.ECSS_Unit_Type__c,

		Asset__r.ECSS_CompanyCode__c,
		
		Asset__r.ECSS_Owned_By__r.SapAccountID__c,

		Asset__r.ECSS_ProfitCenter__c,

        ECSS_Type__c

    FROM QuoteLineItem

    WHERE QuoteId IN :quoteIds AND (ECSS_Type__c='RENT' or ECSS_Type__c='Rent')

    AND Asset__c != null

];

system.debug(qlis);

            

            for (QuoteLineItem qli : qlis) {

                system.debug('ASSET'+qli.Asset__c+'--'+qli.Asset__r.External_Id__c);

                if (String.isBlank(qli.Asset__r.External_Id__c)) {

                    

                    Asset_Event__e eventRecord = new Asset_Event__e();

                    eventRecord.ECSS_AssetId__c            = qli.Asset__c;

                    eventRecord.ECSS_AvailabilityDate__c   = qli.Asset__r.ECSS_Availability_Date__c;

                    eventRecord.ECSS_FeaturesAmenities__c  = qli.Asset__r.ECSS_Features_Amenities__c;

                    eventRecord.ECSS_Listing_Type__c       = qli.Asset__r.ECSS_Listing_Type__c;

                    eventRecord.ECSS_Name__c               = qli.Asset__r.Name;

                    eventRecord.ECSS_Number_of_Baths__c    = qli.Asset__r.ECSS_Number_of_Baths__c;

                    eventRecord.ECSS_NumberofCheques__c    = qli.Asset__r.ECSS_Number_of_Cheques__c;

                    eventRecord.ECSS_OwnerEmailAddress__c  = qli.Asset__r.Owner.Email;

                    eventRecord.ECSS_OwnerMobileNumber__c  = qli.Asset__r.Owner.Phone;

                    

                    eventRecord.ECSS_PlotSize__c           = qli.Asset__r.ECSS_Plot_Size__c;

                    eventRecord.ECSS_Property_Size__c      = qli.Asset__r.ECSS_Property_Size_Built_up_area__c;

                    eventRecord.ECSS_TitleDeedNumber__c    = qli.Asset__r.ECSS_Title_Deed_Number__c;

                    eventRecord.ECSS_TrakheesiPermitNumber__c = qli.Asset__r.ECSS_Trakheesi_Permit_Number__c;

                    eventRecord.ECSS_Unit_Type__c          = qli.Asset__r.ECSS_Unit_Type__c;

					eventRecord.ECSS_ProfitCenter__c = qli.Asset__r.ECSS_ProfitCenter__c;

					eventRecord.ECSS_OwnedBy__c = qli.Asset__r.ECSS_Owned_By__r.SapAccountID__c;

					eventRecord.ECSS_CompanyCode__c = qli.Asset__r.ECSS_CompanyCode__c;

                    events.add(eventRecord);

                }

            }

        }

        

        if (!events.isEmpty()) {

            Database.SaveResult[] results = EventBus.publish(events);

            System.debug('Published ' + results.size() + ' Asset Events');

        }*/

    }

    

    

    

    /*

    public static void calculateSecurityDeposit(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {

        for (Quote q : newQuotes) {

            Quote oldQ = oldQuoteMap != null ? oldQuoteMap.get(q.Id) : null;

            

            Boolean rentChanged      = oldQ == null || q.ECSS_RentAmount__c != oldQ.ECSS_RentAmount__c;

            Boolean sdPercentChanged = oldQ == null || q.ECSS_SD__c != oldQ.ECSS_SD__c;

            Boolean sdAmountChanged  = oldQ == null || q.ECSS_SDAmount__c != oldQ.ECSS_SDAmount__c;

            

            

            

            if (q.ECSS_RentAmount__c != null && q.ECSS_RentAmount__c > 0) {

                

                if (q.ECSS_SD__c != null && (sdPercentChanged || rentChanged)) {

                    q.ECSS_SDAmount__c = (q.ECSS_RentAmount__c * q.ECSS_SD__c) / 100;

                }

                else if (q.ECSS_SDAmount__c != null && (sdAmountChanged || rentChanged)) {

                    q.ECSS_SD__c = (q.ECSS_SDAmount__c / q.ECSS_RentAmount__c) * 100;

                }

            }

        }

    }

    

    public static void handleSecurityDeposit(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {

        if (Trigger.isBefore) {

            for (Quote q : newQuotes) {

                Quote oldQ = oldQuoteMap != null ? oldQuoteMap.get(q.Id) : null;

                

                if (q.ECSS_RentAmount__c == null) continue;

                

                Decimal sdPercent = q.ECSS_SD__c;

                if (sdPercent == null && oldQ != null) sdPercent = oldQ.ECSS_SD__c;

                if (sdPercent == null) sdPercent = 5;

                

                q.ECSS_SD__c = sdPercent;

                q.ECSS_SDAmount__c = (q.ECSS_RentAmount__c * sdPercent) / 100;

            }

        }

        

        if (Trigger.isAfter) {

            List<QuoteLineItem> qlisToInsert = new List<QuoteLineItem>();

            List<QuoteLineItem> qlisToDelete = new List<QuoteLineItem>();

            

            PricebookEntry sdPbe = [

                SELECT Id 

                FROM PricebookEntry 

                WHERE Product2.Name = 'Apartment'

                AND IsActive = true

                LIMIT 1

            ];

            

            Set<Id> quoteIds = new Map<Id, Quote>(newQuotes).keySet();

            

            List<QuoteLineItem> existingSdQLIs = [

                SELECT Id, QuoteId, ECSS_Type__c

                FROM QuoteLineItem

                WHERE QuoteId IN :quoteIds

                AND ECSS_Type__c = 'SD'

            ];

            qlisToDelete.addAll(existingSdQLIs);

            

            for (Quote q : newQuotes) {

                Quote oldQ = oldQuoteMap != null ? oldQuoteMap.get(q.Id) : null;

                

                if (q.ECSS_ContractDuration__c == null || q.ECSS_RentAmount__c == null) continue;

                

                Boolean isInsert = (oldQ == null);

                

                Decimal currentYearRent = q.ECSS_RentAmount__c;

                

                for (Integer year = 2; year <= q.ECSS_ContractDuration__c; year++) {

                    Decimal sdAmount = (currentYearRent * q.ECSS_SD__c) / 100;

                    

                    QuoteLineItem qli = new QuoteLineItem();

                    qli.QuoteId = q.Id;

                    qli.PricebookEntryId = sdPbe.Id;

                    qli.Quantity = 1;

                    qli.UnitPrice = sdAmount;

                    qli.ECSS_Type__c = 'SD';

                    qli.Description = 'Security Deposit - Year ' + year;

                    qlisToInsert.add(qli);

                    

                }

            }

            

            if (!qlisToDelete.isEmpty()) delete qlisToDelete;

            if (!qlisToInsert.isEmpty()) insert qlisToInsert;

        }

    }

    */

    public static void SLAWithExpirationDate(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {

    for (Quote q : newQuotes) {

        Quote oldQ = (oldQuoteMap != null ? oldQuoteMap.get(q.Id) : null);



        if (q.ECSS_SLA_Date__c != null && 

            (oldQ == null || q.ECSS_SLA_Date__c != oldQ.ECSS_SLA_Date__c)) {



            q.ExpirationDate = q.ECSS_SLA_Date__c.date();

        }

    }

}

    /*

    public static void createPaymentDocumentsForQuote(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {

    Set<Id> quoteIds = new Set<Id>();



    for (Quote q : newQuotes) {

        Quote oldQ = oldQuoteMap != null && oldQuoteMap.containsKey(q.Id) ? oldQuoteMap.get(q.Id) : null;



        if (q.Status == 'In Progress' && (oldQ == null || oldQ.Status != 'In Progress')) {

            quoteIds.add(q.Id);

        }

    }



    if (quoteIds.isEmpty()) return;



    Map<Id, Map<String, Document__c>> quoteToDocs = new Map<Id, Map<String, Document__c>>();

    for (Document__c d : [

        SELECT Id, ECSS_Quote__c, DocumentType__c, ECSS_SubType__c

        FROM Document__c

        WHERE ECSS_Quote__c IN :quoteIds

        AND DocumentType__c = 'Proof of Payment'

        AND ECSS_SubType__c IN ('TAF','Booking Fee','Security Deposit')

    ]) {

        if (!quoteToDocs.containsKey(d.ECSS_Quote__c)) {

            quoteToDocs.put(d.ECSS_Quote__c, new Map<String, Document__c>());

        }

        quoteToDocs.get(d.ECSS_Quote__c).put(d.ECSS_SubType__c, d);

    }



    Id quoteDocRecordTypeId = [

        SELECT Id 

        FROM RecordType 

        WHERE SObjectType = 'Document__c' 

          AND DeveloperName = 'ECSSQuoteDocument'

        LIMIT 1

    ].Id;



    List<Document__c> docsToInsert = new List<Document__c>();

    List<String> requiredSubTypes = new List<String>{'TAF','Booking Fee','Security Deposit'};



    for (Id qId : quoteIds) {

        Map<String, Document__c> existing = quoteToDocs.containsKey(qId) ? quoteToDocs.get(qId) : new Map<String, Document__c>();

        for (String subtype : requiredSubTypes) {

            if (!existing.containsKey(subtype)) {

                Document__c doc = new Document__c();

                doc.ECSS_Quote__c = qId;

                doc.DocumentType__c = 'Proof of Payment';

                doc.ECSS_SubType__c = subtype;

                doc.RecordTypeId = quoteDocRecordTypeId;

                doc.Status__c = 'Pending';

                docsToInsert.add(doc);

            }

        }

    }



    if (!docsToInsert.isEmpty()) {

        insert docsToInsert;

    }

}

 

  public static void validatePaymentCollectionFlags(List<Quote> newQuotes, Map<Id, Quote> oldQuotes) {

    Set<Id> quoteIds = new Set<Id>();

    for (Quote q : newQuotes) {

        quoteIds.add(q.Id);

    }

    if (quoteIds.isEmpty()) return;



    Map<Id, Map<String, Document__c>> quoteDocs = new Map<Id, Map<String, Document__c>>();

    for (Document__c d : [

        SELECT Id, ECSS_Quote__c, DocumentType__c, ECSS_SubType__c, Status__c

        FROM Document__c

        WHERE ECSS_Quote__c IN :quoteIds

        AND DocumentType__c = 'Proof of Payment'

        AND ECSS_SubType__c IN ('TAF','Booking Fee','Security Deposit')

    ]) {

        if (!quoteDocs.containsKey(d.ECSS_Quote__c)) {

            quoteDocs.put(d.ECSS_Quote__c, new Map<String, Document__c>());

        }

        quoteDocs.get(d.ECSS_Quote__c).put(d.ECSS_SubType__c, d);

    }



    for (Quote q : newQuotes) {

        Map<String, Document__c> docs = quoteDocs.containsKey(q.Id) 

            ? quoteDocs.get(q.Id) 

            : new Map<String, Document__c>();



        if (q.ECSS_Booking_Fee_Collection__c == true) {

            Document__c doc = docs.get('Booking Fee');

            if (doc == null || doc.Status__c != 'Submitted') {

                q.ECSS_Booking_Fee_Collection__c.addError(

                    'Booking Fee Collection cannot be true without a Submitted Booking Fee Proof of Payment document.'

                );

            }

        }



        if (q.ECSS_Security_Deposit_Collection__c == true) {

            Document__c doc = docs.get('Security Deposit');

            if (doc == null || doc.Status__c != 'Submitted') {

                q.ECSS_Security_Deposit_Collection__c.addError(

                    'Security Deposit Collection cannot be true without a Submitted Security Deposit Proof of Payment document.'

                );

            }

        }



        if (q.ECSS_TAF_Collection__c == true) {

            Document__c doc = docs.get('TAF');

            if (doc == null || doc.Status__c != 'Submitted') {

                q.ECSS_TAF_Collection__c.addError(

                    'TAF Collection cannot be true without a Submitted TAF Proof of Payment document.'

                );

            }

        }

    }

}

*/
public static void updateAssetStatusOnQuoteRejection(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {
    Set<Id> rejectedQuoteIds = new Set<Id>();

    for (Quote newQuote : newQuotes) {
        Quote oldQuote = oldQuoteMap.get(newQuote.Id);
        if (newQuote.Status == 'Rejected' && (oldQuote == null || oldQuote.Status != 'Rejected')) {
            rejectedQuoteIds.add(newQuote.Id);
        }
    }

    if (rejectedQuoteIds.isEmpty()) {
        return;
    }

    List<QuoteLineItem> rentQLIs = [
        SELECT Id, Asset__c, ECSS_Type__c
        FROM QuoteLineItem
        WHERE QuoteId IN :rejectedQuoteIds
        AND ECSS_Type__c = 'RENT'
        AND Asset__c != null
    ];

    if (rentQLIs.isEmpty()) {
        return;
    }

    List<Asset> assetsToUpdate = new List<Asset>();
    for (QuoteLineItem qli : rentQLIs) {
        assetsToUpdate.add(new Asset(
            Id = qli.Asset__c,
            Status = 'Available for Lease'
        ));
    }

    if (!assetsToUpdate.isEmpty()) {
        update assetsToUpdate;
    }
}


    
}