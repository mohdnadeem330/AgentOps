public with sharing class ECSS_QuoteLineItemCreator {

    public class FlowInput {
        @InvocableVariable(required=true)
        public Id quoteId;
        
        @InvocableVariable(required=true)
        public List<Id> assetIds;
        
        @InvocableVariable(required= true)
        public Decimal taf;
        
        @InvocableVariable(required = true)
        public Decimal sd;
        
        @InvocableVariable(required = true)
        public Decimal adminFees;
        
        @InvocableVariable(required = true)
        public String pricebook2Id;
    }

    @InvocableMethod(label='Create Quote Line Items for Assets' 
                     description='Creates Rent, SD, and TAF QLIs for selected Assets on a Quote')
    public static void createQLIs(List<FlowInput> requests) {
        List<QuoteLineItem> qlisToInsert = new List<QuoteLineItem>();

        for (FlowInput req : requests) {
            if (req.assetIds == null || req.assetIds.isEmpty() || req.quoteId == null) {
                continue;
            }

            /*Quote q = [
                SELECT Id, Pricebook2Id
                FROM Quote
                WHERE Id = :req.quoteId
                LIMIT 1
            ];*/

            Map<String, QuoteLineItem> existingQLIMap = new Map<String, QuoteLineItem>();
            for (QuoteLineItem qli : [
                SELECT Id, QuoteId, Asset__c, ECSS_Type__c
                FROM QuoteLineItem
                WHERE QuoteId = :req.quoteId
                AND Asset__c IN :req.assetIds
            ]) {
                String typeKey = String.isNotBlank(qli.ECSS_Type__c) ? qli.ECSS_Type__c : 'RENT';
                String key = qli.Asset__c + '-' + typeKey;
                existingQLIMap.put(key, qli);
            }

            List<Asset> assets = [
                SELECT Id, 
                       ECSS_Rent_BaseLine__c, 
                       ECSS_SD_Amount__c
                FROM Asset
                WHERE Id IN :req.assetIds
            ];

            /*Map<Id, Decimal> assetToCommission = new Map<Id, Decimal>();
            for (ECSS_ProjectCommission__c pc : [
                SELECT Id, ECSS_Asset__c, ECSS_LeasingAgentCommission__c
                FROM ECSS_ProjectCommission__c
                WHERE ECSS_Asset__c IN :req.assetIds
            ]) {
                if (pc.ECSS_LeasingAgentCommission__c != null) {
                    assetToCommission.put(pc.ECSS_Asset__c, pc.ECSS_LeasingAgentCommission__c);
                }
            }*/

            Product2 genericProduct = [
                SELECT Id 
                FROM Product2 
                WHERE Name = 'Apartment' 
                LIMIT 1
            ];

            Product2 TAFProduct = [
                SELECT Id 
                FROM Product2 
                WHERE Name = 'TAF' 
                LIMIT 1
            ];

            Product2 SDProduct = [
                SELECT Id 
                FROM Product2 
                WHERE Name = 'Security Deposit' 
                LIMIT 1
            ];
            System.debug('SD: '+SDProduct);
            Product2 AdminFeesProduct = [
                SELECT Id FROM Product2 WHERE Name = 'Admin Fees' LIMIT 1
            ];
            System.debug('Admin Fees: '+AdminFeesProduct);

            PricebookEntry pbeRent = [
                SELECT Id 
                FROM PricebookEntry
                WHERE Product2Id = :genericProduct.Id  
                AND Pricebook2Id = :req.Pricebook2Id
                AND IsActive = true
                LIMIT 1
            ];

            PricebookEntry pbeTAF = [
                SELECT Id 
                FROM PricebookEntry
                WHERE Product2Id = :TAFProduct.Id  
                AND Pricebook2Id = :req.Pricebook2Id
                AND IsActive = true
                LIMIT 1
            ];

            PricebookEntry pbeSD = [
                SELECT Id 
                FROM PricebookEntry
                WHERE Product2Id = :SDProduct.Id  
                AND Pricebook2Id = :req.Pricebook2Id
                AND IsActive = true
                LIMIT 1
            ];
            
            PricebookEntry pbeAdminFees = [
                SELECT Id 
                FROM PricebookEntry
                WHERE Product2Id = :AdminFeesProduct.Id  
                AND Pricebook2Id = :req.Pricebook2Id
                AND IsActive = true
                LIMIT 1
            ];
            for (Asset a : assets) {
                Decimal rentVal = a.ECSS_Rent_BaseLine__c;
                //Decimal sdVal   = a.ECSS_SD_Amount__c;
                //Decimal tafVal  = assetToCommission.containsKey(a.Id) ? assetToCommission.get(a.Id) : null;

                if (rentVal != null && rentVal > 0) {
                    String key = a.Id + '-RENT';
                    if (!existingQLIMap.containsKey(key)) {
                        qlisToInsert.add(new QuoteLineItem(
                            QuoteId         = req.quoteId,
                            Product2Id      = genericProduct.Id,
                            PricebookEntryId= pbeRent.Id,
                            Quantity        = 1,
                            UnitPrice       = rentVal,
                            ECSS_Type__c    = 'RENT',
                            Asset__c        = a.Id
                        ));
                    }
                }
				
                /*if (sdVal != null && sdVal > 0) {
                    String key = a.Id + '-SD';
                    if (!existingQLIMap.containsKey(key)) {
                        qlisToInsert.add(new QuoteLineItem(
                            QuoteId         = req.quoteId,
                            Product2Id      = SDProduct.Id,
                            PricebookEntryId= pbeSD.Id,
                            Quantity        = 1,
                            UnitPrice       = sdVal,
                            ECSS_Type__c    = 'SD',
                            Asset__c        = a.Id
                        ));
                    }
                }

                if (tafVal != null && tafVal > 0) {
                    String key = a.Id + '-TAF';
                    if (!existingQLIMap.containsKey(key)) {
                        qlisToInsert.add(new QuoteLineItem(
                            QuoteId         = req.quoteId,
                            Product2Id      = TAFProduct.Id,
                            PricebookEntryId= pbeTAF.Id,
                            Quantity        = 1,
                            UnitPrice       = tafVal,
                            ECSS_Type__c    = 'TAF',
                            Asset__c        = a.Id
                        ));
                    }
                }*/
            }
            
            QuoteLineItem tafQLI = new QuoteLineItem();
            tafQLI.QuoteId = req.quoteId;
            tafQLI.Product2Id = TAFProduct.Id;
            tafQLI.PricebookEntryId = pbeTAF.Id;
            tafQLI.Quantity = 1;
            tafQLI.UnitPrice = req.taf;
            tafQLI.ECSS_Type__c = 'TAF';
            qlisToInsert.add(tafQLI);
            
            QuoteLineItem sdQLI = new QuoteLineItem();
            sdQLI.QuoteId = req.quoteId;
            sdQLI.Product2Id = SDProduct.Id;
            sdQLI.PricebookEntryId = pbeSD.Id;
            sdQLI.Quantity = 1;
            sdQLI.UnitPrice = req.sd;
            sdQLI.ECSS_Type__c = 'SD';
            qlisToInsert.add(sdQLI);
            
            QuoteLineItem adminQLI = new QuoteLineItem();
            adminQLI.QuoteId = req.quoteId;
            adminQLI.Product2Id = AdminFeesProduct.Id;
            adminQLI.PricebookEntryId = pbeAdminFees.Id;
            adminQLI.Quantity = 1;
            adminQLI.UnitPrice = req.adminFees;
            adminQLI.ECSS_Type__c = 'ADMIN FEES';
            qlisToInsert.add(adminQLI);
        }

        if (!qlisToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(qlisToInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('Error: ' + err.getMessage());
                    }
                }
            }
        }
    }
}