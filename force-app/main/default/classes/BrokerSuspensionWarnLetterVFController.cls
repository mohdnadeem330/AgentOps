public with sharing class BrokerSuspensionWarnLetterVFController {
    public User brokerUserDetails {set; get;}
    public Suspensions_Warning__c suspensionRecord {get; set;}
    public String today { get { return System.now()?.formatGMT('EEE, MMM d yyyy'); }}
    public String suspensionStartDate{set;get;}
    public String suspensionEndDate{set;get;}
    public Map<String,List<String>> mapSuspensionCateSubCategory {set;get;}
    public Integer mapSuspensionCateSubCategorySize { get; set; } 
    public Map<String,Integer> mapSuspensionCateSubCategorySizeEach { get; set; } 
    
    @testVisible static String accountId; 
    @testVisible static String suspenWarnId;
    
    public BrokerSuspensionWarnLetterVFController(){
        brokerUserDetails = new User();
        suspensionRecord = new Suspensions_Warning__c();
        mapSuspensionCateSubCategory = new Map<String, List<String>>();
        mapSuspensionCateSubCategorySizeEach = new Map<String,Integer>();
        
        accountId = ApexPages.currentPage()?.getParameters()?.get('id');
        suspenWarnId = ApexPages.currentPage()?.getParameters()?.get('suspWarnId');
        
        brokerUserDetails = [SELECT Id, Name, Email, Contact.BrokerType__c, Account.Owner.Name, Account.Name, Account.BillingState, 
                             Account.BillingCountry, Account.Email__c, Contact.Name FROM User WHERE 
                             AccountId = :accountId LIMIT 1];

        brokerUserDetails.Account.BillingState = String.isNotBlank(brokerUserDetails?.Account?.BillingState) ? brokerUserDetails?.Account?.BillingState : '';
        
        suspensionRecord = [SELECT Id,SuspensionStartDate__c,SuspensionEndDate__c,SuspensionWarning__c,
                            LeadRegistrationAndManagement__c, LeadRegistrationSubCategory__c,
                            Commission__c, CommissionSubCategory__c,
                            LegalMatters__c, LegalMattersSubCategory__c,
                            Disputes__c, DisputesSubCategory__c,
                            BusinessEthics__c, BusinessEthicsSubCategory__c,
                            MarketingAndCommunications__c, MarketingAndCommunicationsSubCategory__c,
                            BrokerRegistration__c, BrokerRegistrationSubCategory__c,
                            OpenHousesKioskSalesPropertyViewing__c, PropertyViewingsSubCategory__c,
                            AdvertisingMarketing__c, AdvertisingMarketingSubcategory__c,
                            Resale__c, ResaleSubCategory__c,
                            FailureToProtectConfidentialInfo__c, ConfidentialityInfoFailureSubCategory__c,
                            PublishingArticlesWoConsent__c, PublishingWoConsentSubCategory__c,
                            Others__c, OtherReasonforSuspension__c
                            FROM Suspensions_Warning__c WHERE Id = :suspenWarnId];
        
        if(suspensionRecord != null && String.isNotBlank(suspensionRecord.Id)){
            if(suspensionRecord.LeadRegistrationAndManagement__c){
                mapSuspensionCateSubCategory.put('Lead Registration And Management', new List<String>(suspensionRecord.LeadRegistrationSubCategory__c.split(';')));
            }

            if(suspensionRecord.Commission__c){
                mapSuspensionCateSubCategory.put('Commission', new List<String>(suspensionRecord.CommissionSubCategory__c.split(';')));
            }

            if(suspensionRecord.LegalMatters__c){
                mapSuspensionCateSubCategory.put('Legal Matters', new List<String>(suspensionRecord.LegalMattersSubCategory__c.split(';')));
            }

            if(suspensionRecord.Disputes__c){
                mapSuspensionCateSubCategory.put('Dispute', new List<String>(suspensionRecord.DisputesSubCategory__c.split(';')));
            }

            if(suspensionRecord.BusinessEthics__c){
                mapSuspensionCateSubCategory.put('Business Ethics', new List<String>(suspensionRecord.BusinessEthicsSubCategory__c.split(';')));
            }

            if(suspensionRecord.MarketingAndCommunications__c){
                mapSuspensionCateSubCategory.put('Marketing And Communications', new List<String>(suspensionRecord.MarketingAndCommunicationsSubCategory__c.split(';')));
            }

            if(suspensionRecord.BrokerRegistration__c){
                mapSuspensionCateSubCategory.put('Broker Registration', new List<String>(suspensionRecord.BrokerRegistrationSubCategory__c.split(';')));
            }

            if(suspensionRecord.OpenHousesKioskSalesPropertyViewing__c){
                mapSuspensionCateSubCategory.put('Open Houses Kiosk Sales Property Viewing', new List<String>(suspensionRecord.PropertyViewingsSubCategory__c.split(';')));
            }

            if(suspensionRecord.Resale__c){
                mapSuspensionCateSubCategory.put('Resale', new List<String>(suspensionRecord.ResaleSubCategory__c.split(';')));
            }

            if(suspensionRecord.FailureToProtectConfidentialInfo__c){
                mapSuspensionCateSubCategory.put('Failure To Protect Confidential Info', new List<String>(suspensionRecord.ConfidentialityInfoFailureSubCategory__c.split(';')));
            }

            if(suspensionRecord.PublishingArticlesWoConsent__c){
                mapSuspensionCateSubCategory.put('Publishing Articles W/o Consent', new List<String>(suspensionRecord.PublishingWoConsentSubCategory__c.split(';')));
            }

            if(suspensionRecord.Others__c){
                mapSuspensionCateSubCategory.put('Other Reasons', new List<String>{suspensionRecord.OtherReasonforSuspension__c});
            }

            for(String category : mapSuspensionCateSubCategory.keySet()){
                mapSuspensionCateSubCategorySizeEach.put(category, mapSuspensionCateSubCategory.get(category).size());
            }
    
            mapSuspensionCateSubCategorySize = (mapSuspensionCateSubCategory == null || mapSuspensionCateSubCategory.isEmpty()) ? 0 : mapSuspensionCateSubCategory.size();

            suspensionStartDate = ((DateTime) suspensionRecord?.SuspensionStartDate__c)?.formatGMT('EEE, MMM d yyyy');
            suspensionEndDate = ((DateTime) suspensionRecord?.SuspensionEndDate__c) ?.formatGMT('EEE, MMM d yyyy');
        }
    }
}