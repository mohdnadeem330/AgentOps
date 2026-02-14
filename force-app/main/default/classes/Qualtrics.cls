/**********************************************************************************************************************
* Name               : Qualtrics                                                        
* Description        : This class is used to trigger Qualtrics Survey
* Usage              : Lead, Opportunity and Sales Order triggers
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 May 2022      Initial Draft       
  2.0           Muzammil Bajria      11-Nov-2022      Updated field mapping from project location to Unit number for location_code and location_id 
******************************************************************************************************************/
public with sharing class Qualtrics {
    
    /**
    * QualtricsIntegration 
    *
    * Queable class to trigger asyncronous Survey
    * 
    */
    public class QualtricsIntegration implements Queueable,Database.AllowsCallouts {
        set<ID> sObjectIDsToProcess = new set<ID>();
        public QualtricsIntegration(Set<Id> idsToProcess){
            sObjectIDsToProcess = idsToProcess;
        }
        public void execute(QueueableContext context) {
            try{
                if(!sObjectIDsToProcess.isEmpty()){
                    processQualtricsCallout(sObjectIDsToProcess);
                }
           }catch(Exception e){ LoggerService.save(LoggerService.addApexLog(e,'QualtricsIntegration','QualtricsIntegration',''));
           }
            
        }
    }

    /**
    * processQualtricsCallout 
    *
    * This method is used to query the required Survey field and trigger qualtrics survey
    *
    * @param idsToProcess Record IDs to be processed (Support Opportunity, Lead and SalesOrder)
    * @return    map<String,object>  list of select options 
    * 
    */
    public static void processQualtricsCallout(set<ID> idsToProcess){
        map<id,Lead> leadRecordMap = new map<id,Lead>([select Id,FirstName,LastName,Email,MobileCountryCode__c,MobileNumber1__c,MobilePhone,LeadNumber__c,CreatedDate,Status,City,
                                                        LeadSource,EnquiryCategory__c,CustomerBudget__c,BuyRent__c,EnquiryTrigger__c,Project__c,AreaSqmt__c,
                                                        Offer__r.Name,UnitType__c,Nationality__c,Owner.Name,CreatedBy.Name,RetiredReason__c from Lead where id in :idsToProcess]);
        map<id,Opportunity> opportunityRecordmap = new map<id,Opportunity>([select Id,Contact__r.FirstName,Contact__r.LastName,Contact__r.Email,Contact__r.MobileCountryCode__c,Contact__r.MobilePhone__c,OpportunityNumber__c,Owner.Name,
                                                                    CreatedDate,CreatedBy.Name,EnquiryCategory__c,BuyRent__c,Project__c,AreaSqmt__c,UnitType__c,NumberOfBedrooms__c,CustomerBudget__c,
                                                                    EnquiryTrigger__c,MediaSource__c,LeadSource,LeadNumber__c,WinReason__c,LossReason__c,BrokerAgentName__c,BrokerAgencyAccountName__c,
                                                                    Offer__r.Name,lastModifiedDate from opportunity where id in :idsToProcess]);
        map<id,Case> caseRecordmap = new map<id,Case>([select ID,Account.PersonEmail,CaseNumber,Account.FirstName,Account.LastName,Account.MobileCountryCode__pc,Account.MobilePhone__pc,Account.PersonTitle,
                                                                    Account.Name,Account.Nationality__pc, Account.CountryOfResidence__pc,Account.PersonMailingCity,Account.PersonMailingStreet,Category__c,Vertical__c,
                                                                    Account.PersonMailingPostalCode,Account.Gender__pc,Account.MaritalStatus__pc,Account.PersonBirthdate,Account.LanguagePreference__pc,Unit__r.Project__r.Name,
                                                                    AccountId,Unit__c,Unit__r.Name,Unit__r.ProjectName__c,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Name,CaseCategory__c,SubVertical__c,Unit__r.Project__r.ProjectLocation__c,
                                                                    Unit__r.UnitModel__c, Unit__r.UnitType__c, SalesOrder__r.Status__c,SuppliedCompany,SuppliedEmail,SuppliedName,SuppliedPhone,CustomerType__c, Owner.Name,SalesOrder__c ,SalesOrder__r.SoldDate__c, SalesOrder__r.NetAmount__c ,
                                                                    LastModifiedDate,Account.NationalIdNumber__pc from Case where id in :idsToProcess]);
        map<id,SalesOrder__c> salesOrderMap = new map<id,SalesOrder__c> ([select Id,Name,Contact__c,Contact__r.NationalIdNumber__c,Contact__r.NationalIdExpiryDate__c,Contact__r.MobileCountryCode__c,Contact__r.Email,Contact__r.firstName,Contact__r.lastName,
                                                                    Contact__r.MobilePhone,Contact__r.Title,Contact__r.MiddleName,Contact__r.Name,Contact__r.Nationality__c,Contact__r.MailingCity,Unit__r.TotalRooms__c,
                                                                    Contact__r.MailingStreet,Contact__r.MailingPostalCode,Contact__r.Gender__c,Contact__r.MaritalStatus__c,Contact__r.Birthdate,Contact__r.MobilePhone__c,
                                                                    Contact__r.LanguagePreference__c,Contact__r.ResidentStatus__c,ProjectName__c,Unit__r.BuildingSectionName__r.Name,
                                                                    UnitType__c,Unit__r.UnitModel__c,Unit__r.PropertyUsage__c,UnitTotalArea__c,Status__c,NetAmount__c,Account__c,
                                                                    Account__r.Name ,Unit__r.Project__r.ProjectLocation__c,MortgageBank__c,LastModifiedDate,OpportunitySaleType__c,Opportunity__r.BrokerAgencyAccountName__c,
                                                                    Opportunity__r.BrokerAgentName__c,SalesManagerName__c,Unit__r.Name,Unit__c from SalesOrder__c where id in :idsToProcess]);
        Map<Id, HexaBPM__Service_Request__c> serviceRequestMap = new Map<Id, HexaBPM__Service_Request__c> ([SELECT Id, BuyerName__c, BuyerName__r.NationalIdNumber__pc, BuyerName__r.NationalIdExpiryDate__pc, BuyerName__r.PersonEmail, 
                                                                            BuyerName__r.firstName, BuyerName__r.lastName, BuyerName__r.MobileCountryCode__pc, BuyerName__r.MobilePhone__pc, BuyerName__r.PersonTitle, recordTypeId, 
                                                                            recordType.Name, BuyerName__r.MiddleName, BuyerName__r.Name, BuyerName__r.Nationality__pc, BuyerName__r.BillingCity, BuyerName__r.BillingStreet, isPlot__c,
                                                                            BuyerName__r.BillingPostalCode, BuyerName__r.Gender__pc, BuyerName__r.MaritalStatus__pc, BuyerName__r.PersonBirthdate, BuyerName__r.PersonMobilePhone, 
                                                                            BuyerName__r.ResidentStatus__pc, BuyerName__r.LanguagePreference__pc, HexaBPM__Customer__c, HexaBPM__Customer__r.NationalIdNumber__pc,Unit__c,
                                                                            HexaBPM__Customer__r.NationalIdExpiryDate__pc, HexaBPM__Customer__r.PersonEmail, HexaBPM__Customer__r.firstName, HexaBPM__Customer__r.lastName, 
                                                                            HexaBPM__Customer__r.MobileCountryCode__pc, HexaBPM__Customer__r.MobilePhone__pc, HexaBPM__Customer__r.PersonTitle, HexaBPM__Customer__r.MiddleName, 
                                                                            HexaBPM__Customer__r.Name, HexaBPM__Customer__r.Nationality__pc, HexaBPM__Customer__r.BillingCity, HexaBPM__Customer__r.BillingStreet, 
                                                                            HexaBPM__Customer__r.BillingPostalCode, HexaBPM__Customer__r.Gender__pc, HexaBPM__Customer__r.MaritalStatus__pc, HexaBPM__Customer__r.PersonBirthdate, 
                                                                            HexaBPM__Customer__r.PersonMobilePhone, HexaBPM__Customer__r.LanguagePreference__pc, HexaBPM__Customer__r.ResidentStatus__pc, SalesOrder__r.Unit__r.Project__r.Name, SalesOrder__r.Unit__r.name,
                                                                            SalesOrder__c, SalesOrder__r.ProjectName__c, SalesOrder__r.Unit__r.BuildingSectionName__r.Name, SalesOrder__r.UnitType__c, HandoverDetail__r.CustomerDesnaggingDate__c,
                                                                            SalesOrder__r.Unit__r.UnitModel__c, SalesOrder__r.UnitTotalArea__c, SalesOrder__r.Unit__r.TotalRooms__c, SalesOrder__r.Unit__r.PropertyUsage__c, 
                                                                            SalesOrder__r.Name, SalesOrder__r.Status__c, SalesOrder__r.BookingDate__c, SalesOrder__r.NetAmount__c, SalesOrder__r.Account__c, SalesOrder__r.Account__r.Name, 
                                                                            SalesOrder__r.Unit__r.Project__r.ProjectLocation__c, SalesOrder__r.MortgageBank__c, SalesOrder__r.LastModifiedDate, SalesOrder__r.OpportunitySaleType__c, 
                                                                            SalesOrder__r.Opportunity__r.BrokerAgencyAccountName__c, SalesOrder__r.Opportunity__r.BrokerAgentName__c, SalesOrder__r.SalesManagerName__c 
                                                                            FROM HexaBPM__Service_Request__c WHERE Id IN :idsToProcess]);
        APISetting__mdt  qualtricsAPIConfiguration = Utilities.getServiceDetails(Constants.QUALTRICS);
        Organization orgDetails = Utilities.getOrganizationDetails();
        Map<String,String> headerConfiguration = (Map<String,String>)JSON.deserialize(qualtricsAPIConfiguration.Headers__c, Map<String,String>.class);
        String endPointURL = qualtricsAPIConfiguration.SandboxURL__c ;
        if(!orgDetails.IsSandbox){
            endPointURL = qualtricsAPIConfiguration.ProductionURL__c ; 
        
        }
        list<sObject> sObjectRecordToUpdate = new list<sObject>();
        for(ID tempRecID : idsToProcess){
            String JSONBody='';
            sObject recordToUpdate;
            //Process individual record
            if(leadRecordMap.containsKey(tempRecID)){
                recordToUpdate=leadRecordMap.get(tempRecID);
                QualtricsRequestWrapper requestRecord = new QualtricsRequestWrapper(leadRecordMap.get(tempRecID));
                JSONBody = JSON.serialize(requestRecord);
                
                recordToUpdate = callQualtricsSurvey(headerConfiguration, endPointURL, qualtricsAPIConfiguration, JSONBody, recordToUpdate);
                sObjectRecordToUpdate.add(recordToUpdate);
            }else if(opportunityRecordmap.containsKey(tempRecID)){
                recordToUpdate=opportunityRecordmap.get(tempRecID);
                QualtricsRequestWrapper requestRecord = new QualtricsRequestWrapper(opportunityRecordmap.get(tempRecID));
                JSONBody = JSON.serialize(requestRecord,true);
                
                recordToUpdate = callQualtricsSurvey(headerConfiguration, endPointURL, qualtricsAPIConfiguration, JSONBody, recordToUpdate);
                sObjectRecordToUpdate.add(recordToUpdate);
            }else if(salesOrderMap.containsKey(tempRecID)){
                recordToUpdate=salesOrderMap.get(tempRecID);
                QualtricsRequestSalesOrderWrapper requestRecord = new QualtricsRequestSalesOrderWrapper(salesOrderMap.get(tempRecID));
                JSONBody = JSON.serialize(requestRecord);
                
                recordToUpdate = callQualtricsSurvey(headerConfiguration, endPointURL, qualtricsAPIConfiguration, JSONBody, recordToUpdate);
                sObjectRecordToUpdate.add(recordToUpdate);
            } else if(serviceRequestMap.containsKey(tempRecID)){
                recordToUpdate=serviceRequestMap.get(tempRecID);
                QualtricsRequestSRPropertyTransferWrapper sellerRequestRecord = new QualtricsRequestSRPropertyTransferWrapper(serviceRequestMap.get(tempRecID), Constants.CUSTOMER_ESIGN);
                JSONBody = JSON.serialize(sellerRequestRecord);
                recordToUpdate = callQualtricsSurvey(headerConfiguration, endPointURL, qualtricsAPIConfiguration, JSONBody, recordToUpdate);
                
                if (serviceRequestMap.get(tempRecID).RecordType.Name == Constants.PROPERTY_TRANSFER_RT) {
                    QualtricsRequestSRPropertyTransferWrapper buyerRequestRecord = new QualtricsRequestSRPropertyTransferWrapper(serviceRequestMap.get(tempRecID), Constants.BUYER_ESIGN);
                    JSONBody = JSON.serialize(buyerRequestRecord);
                    recordToUpdate = callQualtricsSurvey(headerConfiguration, endPointURL, qualtricsAPIConfiguration, JSONBody, recordToUpdate);    
                }
                sObjectRecordToUpdate.add(recordToUpdate);
            }else if(caseRecordmap.containsKey(tempRecID)){
                recordToUpdate=caseRecordmap.get(tempRecID);
                QualtricsCaseWrapper requestRecord = new QualtricsCaseWrapper(caseRecordmap.get(tempRecID));
                JSONBody = JSON.serialize(requestRecord);
                
                recordToUpdate = callQualtricsSurvey(headerConfiguration, endPointURL, qualtricsAPIConfiguration, JSONBody, recordToUpdate);
                sObjectRecordToUpdate.add(recordToUpdate);
            }
        }
        if(!sObjectRecordToUpdate.isEmpty() ){
            update sObjectRecordToUpdate;
        }
    }

    public static SObject callQualtricsSurvey(Map<String,String> headerConfiguration, String endPointURL, APISetting__mdt qualtricsAPIConfiguration, String JSONBody, SObject recordToUpdate) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        for(String headerName : headerConfiguration.keySet()){
            request.setHeader(headerName, headerConfiguration.get(headerName));
        } 
        request.setEndpoint(endPointURL);
        request.setMethod(qualtricsAPIConfiguration.Method__c);
        request.setBody(JSONBody);
        System.debug('JSONBody *******'+JSONBody);
        request.setTimeout(120000);
        HttpResponse response = http.send(request);
        System.debug('response.getBody()*******'+response.getBody());
        //TODO Update Survey Sent details
        //Parse response
        boolean success = (response!=null && response.getStatusCode() == 200);
        
        System.debug('recordToUpdate>>>' + recordToUpdate);
        if(success){
            map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
            recordToUpdate.put('QualtricsIntegrationStatus__c', Constants.QUALTRICS_SENT);
            recordToUpdate.put('QualtricsQueueID__c', String.valueOf(responseMap.get('QueueId')));
        }else{
            recordToUpdate.put('QualtricsIntegrationStatus__c',Constants.QUALTRICS_FAILED);
        }
        System.debug('recordToUpdate>>>' + recordToUpdate);
        return recordToUpdate;
    }
  
    /**
    * QualtricsRequestSalesOrderWrapper 
    * Sales Order input structure for Qualtrics Survey
    */
    class QualtricsRequestSalesOrderWrapper{
        String RECID;
        String EMIRATES_ID;
        Date EXPIRATION_DATE;
        String TRIGGER_SOURCE;
        String TRIGGER_TOUCHPOINT;
        String email;
        String firstName;
        String lastName;
        String mobileNo;
        String ConfigGroup;
        String TITLE;
        String PERSON_MIDDLE_NAME;
        String COMPLETE_PARTY_NAME;
        String NATIONALITY;
        String COUNTRY_OF_RESIDENCE;
        String CITY;
        String ADDRESS1;
        String POSTAL_CODE;
        String GENDER;
        String MARITAL_STATUS;
        Date DATE_OF_BIRTH;
        String COMPLETE_OTHER_PHONE_NUMBER;
        String PROFFERED_LANGUAGE_METHOD;
        String PREFERRED_CONTACT_METHOD;
        String NAME_IN_ARABIC;
        String FACEBOOK_NAME;
        String EMIRATE;
        String PARTY_ID;
        String p_sales_cloud_contact_id;
        String TWITTER_HANDLE;
        String LINKEDIN_ID;
        String RESIDENCY_STATUS;
        String PROPERTY_NAME;
        String COMMUNITY_NAME;
        String BUILDING_NAME;
        String LOCATION_CODE;
        String UNIT_TYPE;
        String UNIT_MODEL;
        String UNIT_AREA;
        String ROOMS;
        String PROPERTY_USAGE;
        String AREA_UOM;
        String SALES_ORDER_NUM;
        String ORDER_STATUS;
        Date ORDER_DATE;
        Decimal NET_AMOUNT;
        String ACCOUNT_NUMBER;
        String ACCOUNT_NAME;
        String SALES_ORDER_ID;
        String CUST_ACCOUNT_ID;
        String LOCATION_ID;
        String MORTGAGE_BANK_NAME;
        String MORTGAGE_FLAG;
        String LAST_CUSTOMER_NAME;
        Date LAST_TRANSFER_DATE;
        String TRANSFER_UNIT_FLAG;
        Date REC_UPDATE_DATE;
        String SalesType;
        String BrokerAgencyName;
        String BrokerAgentName;
        Date BrokerInteractionDate;
        String HOAGENTNAME;
        String ALDAR_SALES_AGENT;
        String SFUNITID;

        public QualtricsRequestSalesOrderWrapper(SalesOrder__c salesOrderRecord ){
            RECID = salesOrderRecord.Id ;
            EMIRATES_ID = salesOrderRecord.Contact__r.NationalIdNumber__c ;
            EXPIRATION_DATE = salesOrderRecord.Contact__r.NationalIdExpiryDate__c!=null ? date.newinstance(salesOrderRecord.Contact__r.NationalIdExpiryDate__c.year(), salesOrderRecord.Contact__r.NationalIdExpiryDate__c.month(), salesOrderRecord.Contact__r.NationalIdExpiryDate__c.day()):null;
            email = salesOrderRecord.Contact__r.Email ;
            firstName = salesOrderRecord.Contact__r.firstName ;
            lastName = salesOrderRecord.Contact__r.lastName;
            mobileNo = salesOrderRecord.Contact__r.MobileCountryCode__c + salesOrderRecord.Contact__r.MobilePhone__c;
            TITLE = salesOrderRecord.Contact__r.Title ;
            PERSON_MIDDLE_NAME = salesOrderRecord.Contact__r.MiddleName ;
            COMPLETE_PARTY_NAME =  salesOrderRecord.Contact__r.Name ;
            NATIONALITY = salesOrderRecord.Contact__r.Nationality__c ;
            //COUNTRY_OF_RESIDENCE = salesOrderRecord.Contact__r.Name ;
            CITY = salesOrderRecord.Contact__r.MailingCity ;
            ADDRESS1 = salesOrderRecord.Contact__r.MailingStreet ;
            POSTAL_CODE = salesOrderRecord.Contact__r.MailingPostalCode ;
            GENDER = salesOrderRecord.Contact__r.Gender__c ;
            MARITAL_STATUS = salesOrderRecord.Contact__r.MaritalStatus__c ;
            DATE_OF_BIRTH = salesOrderRecord.Contact__r.Birthdate!=null ? date.newinstance(salesOrderRecord.Contact__r.Birthdate.year(), salesOrderRecord.Contact__r.Birthdate.month(), salesOrderRecord.Contact__r.Birthdate.day()):null;
            COMPLETE_OTHER_PHONE_NUMBER = salesOrderRecord.Contact__r.MobilePhone__c;
            PROFFERED_LANGUAGE_METHOD = salesOrderRecord.Contact__r.LanguagePreference__c ;
            //PREFERRED_CONTACT_METHOD = salesOrderRecord.Id ;
            //NAME_IN_ARABIC = salesOrderRecord.Id ;
            //FACEBOOK_NAME = salesOrderRecord.Id ;
            //EMIRATE = salesOrderRecord.Id ;
            PARTY_ID = salesOrderRecord.Contact__c ;
            p_sales_cloud_contact_id = salesOrderRecord.Contact__c ;
            //TWITTER_HANDLE = salesOrderRecord.Id ;
            //LINKEDIN_ID = salesOrderRecord.Id ;
            RESIDENCY_STATUS = salesOrderRecord.Contact__r.ResidentStatus__c ;
            PROPERTY_NAME = salesOrderRecord.ProjectName__c ;
            //COMMUNITY_NAME = salesOrderRecord.Id ;
            BUILDING_NAME = salesOrderRecord.Unit__r.BuildingSectionName__r.Name ;
            LOCATION_CODE = salesOrderRecord.Unit__r.Name ; 
            UNIT_TYPE = salesOrderRecord.UnitType__c ;
            UNIT_MODEL = salesOrderRecord.Unit__r.UnitModel__c ;
            UNIT_AREA = String.ValueOf(salesOrderRecord.UnitTotalArea__c) ;
            ROOMS = salesOrderRecord.Unit__r.TotalRooms__c ;
            PROPERTY_USAGE = salesOrderRecord.Unit__r.PropertyUsage__c ;
            AREA_UOM = String.ValueOf(salesOrderRecord.UnitTotalArea__c) ;
            SALES_ORDER_NUM = salesOrderRecord.Name ;
            ORDER_STATUS = salesOrderRecord.Status__c ;
            //****ORDER_DATE = salesOrderRecord.Id ;
            NET_AMOUNT = salesOrderRecord.NetAmount__c ;
            ACCOUNT_NUMBER = salesOrderRecord.Account__c ;
            ACCOUNT_NAME = salesOrderRecord.Account__r.Name ;
            SALES_ORDER_ID = salesOrderRecord.Name ;
            CUST_ACCOUNT_ID = salesOrderRecord.Account__c  ;
            LOCATION_ID = salesOrderRecord.Unit__r.Name;
            MORTGAGE_BANK_NAME = salesOrderRecord.MortgageBank__c ;
            SFUNITID=salesOrderRecord.Unit__c ;
            MORTGAGE_FLAG = salesOrderRecord.MortgageBank__c!=null?'YES':'NO' ;
            LAST_CUSTOMER_NAME = salesOrderRecord.Contact__r.lastName;
            //****LAST_TRANSFER_DATE = salesOrderRecord.Id ;
            //TRANSFER_UNIT_FLAG = salesOrderRecord.Id ;
            REC_UPDATE_DATE = date.newinstance(salesOrderRecord.LastModifiedDate.year(), salesOrderRecord.LastModifiedDate.month(), salesOrderRecord.LastModifiedDate.day()) ;
            SalesType = salesOrderRecord.OpportunitySaleType__c ;
            BrokerAgencyName = salesOrderRecord.Opportunity__r.BrokerAgencyAccountName__c;
            BrokerAgentName = salesOrderRecord.Opportunity__r.BrokerAgentName__c;
            //****BrokerInteractionDate = salesOrderRecord.Id ;
            //HOAGENTNAME = salesOrderRecord.Id ;
            ALDAR_SALES_AGENT = salesOrderRecord.SalesManagerName__c ;
            TRIGGER_SOURCE = 'SALESFORCE' ;
            TRIGGER_TOUCHPOINT = salesOrderRecord.Status__c.equalsIgnoreCase(Constants.OPPO_UNIT_STATUS_PENDING)? 'PRODALNewBookingPurchase' : 'PRODALOverAllSalesPurchase' ;
            ConfigGroup = salesOrderRecord.Status__c.equalsIgnoreCase(Constants.OPPO_UNIT_STATUS_PENDING)? 'PRODALNewBookingPurchase' : 'PRODALOverAllSalesPurchase' ; 
        }
    }

    /**
    * QualtricsRequestWrapper 
    * Lead/opportunity input structure for Qualtrics Survey
    */
    class QualtricsRequestWrapper{
        Id RECID;
        String firstName;
        String lastName;
        String email;
        String mobileNo;
        String LEAD_ID;   
        String LEAD_NUMBER;   
        Date CREATION_DATE;
        String LEAD_NAME;
        String STATUS_CODE;
        String RANK;
        String OPPORTUNITY_WINLOSS_REASON;
        String CITY;
        String LEAD_SOURCE;
        String ENQUIRY_CATEGORY;
        String BUDGETLIMIT_AED;
        String BUY_RENT;
        String ENQUIRY_TRIGGER;
        String PROPERTY;
        String ENQUIRY_SOURCE;
        String AREA;
        String OFFER;
        String DataSource;
        String UNIT_TYPE;
        String NATIONALITY;
        String OWNER;
        String CREATED_BY;
        String PARTY_ID;
        String LEAD_RETIRE_REASON_NAME;
        String TRIGGER_SOURCE;
        String TRIGGER_TOUCHPOINT;
        String ConfigGroup;

        //Opportunity
        Id OPTY_ID;
        String BUDGET_LIMIT;
        String OPTY_NUMBER;
        String SALES_METHOD_ID;
        String NO_OF_BEDROOMS;
        String BUDGETLIMIT;
        String MEDIA_NAME;
        String BrokerAgentName;
        String BrokerAgencyName;
        Date REC_UPDATE_DATE;
        
        public QualtricsRequestWrapper(Lead leadRecord){
            RECID = leadRecord.Id;
            firstName = leadRecord.FirstName;
            lastName = leadRecord.LastName;
            email = leadRecord.Email;
            mobileNo =leadRecord.MobileCountryCode__c + leadRecord.MobileNumber1__c ;
            LEAD_ID = leadRecord.Id;
            LEAD_NUMBER = leadRecord.LeadNumber__c;
            CREATION_DATE = date.newinstance(leadRecord.CreatedDate.year(), leadRecord.CreatedDate.month(), leadRecord.CreatedDate.day());
            //PRIMARY_CONTACT_ID =
            //LEAD_NAME
            STATUS_CODE = leadRecord.Status;
            //RANK
            //OPPORTUNITY_CLOSE_REASON
            CITY=leadRecord.City;
            LEAD_SOURCE = leadRecord.LeadSource;
            ENQUIRY_CATEGORY = leadRecord.EnquiryCategory__c;
            BUDGETLIMIT_AED = leadRecord.CustomerBudget__c;
            BUY_RENT = leadRecord.BuyRent__c;
            ENQUIRY_TRIGGER = leadRecord.EnquiryTrigger__c;
            PROPERTY = leadRecord.Project__c;
            //ENQUIRY_SOURCE
            AREA = leadRecord.AreaSqmt__c;
            OFFER = leadRecord.Offer__r.Name;
            DataSource = leadRecord.LeadSource;
            UNIT_TYPE = leadRecord.UnitType__c;
            NATIONALITY = leadRecord.Nationality__c;
            OWNER = leadRecord.Owner.Name;
            CREATED_BY = leadRecord.CreatedBy.Name;
            //PARTY_ID
            LEAD_RETIRE_REASON_NAME = leadRecord.RetiredReason__c;
            TRIGGER_SOURCE = 'SALESFORCE';
            TRIGGER_TOUCHPOINT ='SUSPECT RETIRED';
            ConfigGroup = 'PRODALSuspectExp';
        }
        public QualtricsRequestWrapper(Opportunity opportunityRecord){
            RECID = opportunityRecord.Id;
            firstName = opportunityRecord.Contact__r.FirstName;
            lastName = opportunityRecord.Contact__r.LastName;
            email = opportunityRecord.Contact__r.Email;
            mobileNo = opportunityRecord.Contact__r.MobileCountryCode__c +opportunityRecord.Contact__r.MobilePhone__c;
            OPTY_ID = opportunityRecord.Id;
            OPTY_NUMBER = opportunityRecord.OpportunityNumber__c;
            OWNER = opportunityRecord.Owner.Name;
            CREATION_DATE = date.newinstance(opportunityRecord.CreatedDate.year(), opportunityRecord.CreatedDate.month(), opportunityRecord.CreatedDate.day());
            CREATED_BY = opportunityRecord.CreatedBy.Name;
            //SALES_METHOD_ID
            ENQUIRY_CATEGORY = opportunityRecord.EnquiryCategory__c;
            BUY_RENT = opportunityRecord.BuyRent__c;
            PROPERTY = opportunityRecord.Project__c;
            AREA = opportunityRecord.AreaSqmt__c;
            UNIT_TYPE = opportunityRecord.UnitType__c;
            NO_OF_BEDROOMS = opportunityRecord.NumberOfBedrooms__c;
            BUDGET_LIMIT = opportunityRecord.CustomerBudget__c;
            ENQUIRY_TRIGGER= opportunityRecord.EnquiryTrigger__c;
            MEDIA_NAME = opportunityRecord.MediaSource__c;
            DataSource = opportunityRecord.LeadSource;
            LEAD_NUMBER = opportunityRecord.LeadNumber__c;
            OPPORTUNITY_WINLOSS_REASON = (opportunityRecord.WinReason__c!=null?opportunityRecord.WinReason__c:'') + (opportunityRecord.LossReason__c!=null?opportunityRecord.LossReason__c:'' );
            BrokerAgentName = opportunityRecord.BrokerAgentName__c;
            BrokerAgencyName = opportunityRecord.BrokerAgencyAccountName__c;
            OFFER = opportunityRecord.Offer__r.Name;
            REC_UPDATE_DATE = date.newinstance(opportunityRecord.lastModifiedDate.year(), opportunityRecord.lastModifiedDate.month(), opportunityRecord.lastModifiedDate.day());
            ConfigGroup = 'PRODALOpportunityExp';
            TRIGGER_SOURCE = 'SALESFORCE';
            TRIGGER_TOUCHPOINT= 'OPPORTUNITY RETIRED';
        }
    }
  
    /**
    * QualtricsRequestSRPropertyTransferWrapper 
    * Service Request input structure for Qualtrics Survey
    */
    class QualtricsRequestSRPropertyTransferWrapper {
        String RECID;
        String EMIRATES_ID;
        Date EXPIRATION_DATE;
        String TRIGGER_SOURCE;
        String TRIGGER_TOUCHPOINT;
        String email;
        String firstName;
        String lastName;
        String mobileNo;
        String ConfigGroup;
        String TITLE;
        String PERSON_MIDDLE_NAME;
        String COMPLETE_PARTY_NAME;
        String NATIONALITY;
        String COUNTRY_OF_RESIDENCE; //Not
        String CITY;
        String ADDRESS1;
        String POSTAL_CODE;
        String GENDER;
        String MARITAL_STATUS;
        Date DATE_OF_BIRTH;
        String COMPLETE_OTHER_PHONE_NUMBER;
        String PROFFERED_LANGUAGE_METHOD;
        String PREFERRED_CONTACT_METHOD; //Not
        String NAME_IN_ARABIC; //Not
        String FACEBOOK_NAME; //Not
        String EMIRATE; //Not
        String PARTY_ID;
        String p_sales_cloud_contact_id;
        String TWITTER_HANDLE; //Not
        String LINKEDIN_ID; //Not
        String RESIDENCY_STATUS;
        String PROPERTY_NAME;
        String COMMUNITY_NAME; //Not
        String BUILDING_NAME;
        String LOCATION_CODE;
        String UNIT_TYPE;
        String UNIT_MODEL;
        String UNIT_AREA;
        String ROOMS;
        String PROPERTY_USAGE;
        String AREA_UOM;
        String SALES_ORDER_NUM;
        String ORDER_STATUS;
        Date ORDER_DATE;
        Decimal NET_AMOUNT;
        String ACCOUNT_NUMBER;
        String ACCOUNT_NAME;
        String SALES_ORDER_ID;
        String CUST_ACCOUNT_ID;
        String LOCATION_ID;
        String MORTGAGE_BANK_NAME;
        String MORTGAGE_FLAG;
        String LAST_CUSTOMER_NAME;
        Date LAST_TRANSFER_DATE;
        String TRANSFER_UNIT_FLAG;
        Date REC_UPDATE_DATE;
        String SalesType;
        String BrokerAgencyName;
        String BrokerAgentName;
        Date BrokerInteractionDate; //Not
        String HOAGENTNAME; //Not
        String ALDAR_SALES_AGENT;
        String SFUNITID;

        public QualtricsRequestSRPropertyTransferWrapper(HexaBPM__Service_Request__c serviceRequestRecord, String customerType) {
            if (customerType == Constants.BUYER_ESIGN) {
                EMIRATES_ID = serviceRequestRecord.BuyerName__r.NationalIdNumber__pc;
                EXPIRATION_DATE = serviceRequestRecord.BuyerName__r.NationalIdExpiryDate__pc;
                email = serviceRequestRecord.BuyerName__r.PersonEmail;
                firstName = serviceRequestRecord.BuyerName__r.firstName;
                lastName = serviceRequestRecord.BuyerName__r.lastName;
                mobileNo = serviceRequestRecord.BuyerName__r.PersonMobilePhone;
                TITLE = serviceRequestRecord.BuyerName__r.PersonTitle;
                PERSON_MIDDLE_NAME = serviceRequestRecord.BuyerName__r.MiddleName;
                COMPLETE_PARTY_NAME =  serviceRequestRecord.BuyerName__r.Name;
                NATIONALITY = serviceRequestRecord.BuyerName__r.Nationality__pc;
                CITY = serviceRequestRecord.BuyerName__r.BillingCity;
                ADDRESS1 = serviceRequestRecord.BuyerName__r.BillingStreet;
                POSTAL_CODE = serviceRequestRecord.BuyerName__r.BillingPostalCode;
                GENDER = serviceRequestRecord.BuyerName__r.Gender__pc;
                MARITAL_STATUS = serviceRequestRecord.BuyerName__r.MaritalStatus__pc;
                DATE_OF_BIRTH = serviceRequestRecord.BuyerName__r.PersonBirthdate;
                COMPLETE_OTHER_PHONE_NUMBER = serviceRequestRecord.BuyerName__r.MobilePhone__pc;
                PROFFERED_LANGUAGE_METHOD = serviceRequestRecord.BuyerName__r.LanguagePreference__pc;
                RESIDENCY_STATUS = serviceRequestRecord.BuyerName__r.ResidentStatus__pc;
                LAST_CUSTOMER_NAME = serviceRequestRecord.BuyerName__r.lastName;
                PARTY_ID = serviceRequestRecord.BuyerName__c;
                p_sales_cloud_contact_id = serviceRequestRecord.BuyerName__c;
                RECID = serviceRequestRecord.Id + '#' + serviceRequestRecord.BuyerName__c;
            } else if (customerType == Constants.CUSTOMER_ESIGN) {
                EMIRATES_ID = serviceRequestRecord.HexaBPM__Customer__r.NationalIdNumber__pc;
                EXPIRATION_DATE = serviceRequestRecord.HexaBPM__Customer__r.NationalIdExpiryDate__pc;
                email = serviceRequestRecord.HexaBPM__Customer__r.PersonEmail;
                firstName = serviceRequestRecord.HexaBPM__Customer__r.firstName;
                lastName = serviceRequestRecord.HexaBPM__Customer__r.lastName;
                mobileNo = serviceRequestRecord.HexaBPM__Customer__r.PersonMobilePhone;
                TITLE = serviceRequestRecord.HexaBPM__Customer__r.PersonTitle;
                PERSON_MIDDLE_NAME = serviceRequestRecord.HexaBPM__Customer__r.MiddleName;
                COMPLETE_PARTY_NAME =  serviceRequestRecord.HexaBPM__Customer__r.Name;
                NATIONALITY = serviceRequestRecord.HexaBPM__Customer__r.Nationality__pc;
                CITY = serviceRequestRecord.HexaBPM__Customer__r.BillingCity;
                ADDRESS1 = serviceRequestRecord.HexaBPM__Customer__r.BillingStreet;
                POSTAL_CODE = serviceRequestRecord.HexaBPM__Customer__r.BillingPostalCode;
                GENDER = serviceRequestRecord.HexaBPM__Customer__r.Gender__pc;
                MARITAL_STATUS = serviceRequestRecord.HexaBPM__Customer__r.MaritalStatus__pc;
                DATE_OF_BIRTH = serviceRequestRecord.HexaBPM__Customer__r.PersonBirthdate;
                COMPLETE_OTHER_PHONE_NUMBER = serviceRequestRecord.HexaBPM__Customer__r.MobilePhone__pc;
                PROFFERED_LANGUAGE_METHOD = serviceRequestRecord.HexaBPM__Customer__r.LanguagePreference__pc;
                RESIDENCY_STATUS = serviceRequestRecord.HexaBPM__Customer__r.ResidentStatus__pc;
                LAST_CUSTOMER_NAME = serviceRequestRecord.HexaBPM__Customer__r.lastName;
                PARTY_ID = serviceRequestRecord.HexaBPM__Customer__c;
                p_sales_cloud_contact_id = serviceRequestRecord.HexaBPM__Customer__c;
                RECID = serviceRequestRecord.Id + '#' + serviceRequestRecord.HexaBPM__Customer__c;
            }
            SFUNITID = serviceRequestRecord.Unit__c;
            PROPERTY_NAME = serviceRequestRecord.SalesOrder__r.Unit__r.Project__r.Name;
            BUILDING_NAME = serviceRequestRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.Name;
            LOCATION_CODE = serviceRequestRecord.SalesOrder__r.Unit__r.Name;
            UNIT_TYPE = serviceRequestRecord.SalesOrder__r.UnitType__c;
            UNIT_MODEL = serviceRequestRecord.SalesOrder__r.Unit__r.UnitModel__c;
            UNIT_AREA = String.ValueOf(serviceRequestRecord.SalesOrder__r.UnitTotalArea__c);
            ROOMS = serviceRequestRecord.SalesOrder__r.Unit__r.TotalRooms__c;
            PROPERTY_USAGE = serviceRequestRecord.SalesOrder__r.Unit__r.PropertyUsage__c;
            AREA_UOM = String.ValueOf(serviceRequestRecord.SalesOrder__r.UnitTotalArea__c);
            SALES_ORDER_NUM = serviceRequestRecord.SalesOrder__r.Name;
            ORDER_STATUS = serviceRequestRecord.SalesOrder__r.Status__c;
            ORDER_DATE = serviceRequestRecord.SalesOrder__r.BookingDate__c;
            NET_AMOUNT = serviceRequestRecord.SalesOrder__r.NetAmount__c;
            ACCOUNT_NUMBER = serviceRequestRecord.SalesOrder__r.Account__c;
            ACCOUNT_NAME = serviceRequestRecord.SalesOrder__r.Account__r.Name;
            SALES_ORDER_ID = serviceRequestRecord.SalesOrder__r.Name;
            CUST_ACCOUNT_ID = serviceRequestRecord.SalesOrder__r.Account__c ;
            LOCATION_ID = serviceRequestRecord.SalesOrder__r.Unit__r.Project__r.ProjectLocation__c;
            MORTGAGE_BANK_NAME = serviceRequestRecord.SalesOrder__r.MortgageBank__c;
            MORTGAGE_FLAG = serviceRequestRecord.SalesOrder__r.MortgageBank__c != null ? 'YES' : 'NO';
            REC_UPDATE_DATE = date.newinstance(serviceRequestRecord.SalesOrder__r.LastModifiedDate.year(), serviceRequestRecord.SalesOrder__r.LastModifiedDate.month(), serviceRequestRecord.SalesOrder__r.LastModifiedDate.day());
            SalesType = serviceRequestRecord.SalesOrder__r.OpportunitySaleType__c;
            BrokerAgencyName = serviceRequestRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccountName__c;
            BrokerAgentName = serviceRequestRecord.SalesOrder__r.Opportunity__r.BrokerAgentName__c;
            ALDAR_SALES_AGENT = serviceRequestRecord.SalesOrder__r.SalesManagerName__c;
            LAST_TRANSFER_DATE = Date.today();
            TRANSFER_UNIT_FLAG = 'YES';
            TRIGGER_SOURCE = 'SALESFORCE';
            if (serviceRequestRecord.RecordType.Name == Constants.PROPERTY_TRANSFER_RT) {
                TRIGGER_TOUCHPOINT = customerType == Constants.BUYER_ESIGN ? 'TRANSFER_SR_BUY' : 'TRANSFER_SR_SELL';
                ConfigGroup = customerType == Constants.BUYER_ESIGN ? 'PRODALPropertyBuyerExp' : 'PRODALPropertySellerExp';
            } else if (serviceRequestRecord.RecordType.Name == Constants.PROPERTY_TRANSFER_NOC_RT) {
                TRIGGER_TOUCHPOINT = 'NOC_COMPLETE';
                ConfigGroup = 'PRODALServiceExp';
            } else if (serviceRequestRecord.RecordType.Name == Constants.HANDOVER_RT) {
                TRIGGER_TOUCHPOINT = 'HANDOVER_COMPLETE';
                ConfigGroup = serviceRequestRecord.HandoverDetail__r.CustomerDesnaggingDate__c  ==null ? 'ProdHOSnaggingExp':  (serviceRequestRecord.isPlot__c? 'PRODALSalesPlotHandover' :'PRODALSalesHandover');
            }
        }
    }

    class QualtricsCaseWrapper {

        
        String RECID;
        String firstName;
        String lastName;
        String email;
        String mobileNo;
        String TITLE;
        String COMPLETE_PARTY_NAME;
        String NATIONALITY;
        String COUNTRY_OF_RESIDENCE;   
        String CITY;
        String POSTAL_CODE;
        String GENDER;

        String MARITAL_STATUS;
        Date DATE_OF_BIRTH;
        String COMPLETE_OTHER_PHONE_NUMBER;
        String PREFERRED_CONTACT_METHOD;
        String PREFFERED_LANGUAGE_METHOD;
        String EMIRATE;
        String NAME_IN_ARABIC;
        String PARTY_ID;
        String PROPERTY_NAME;
        String COMMUNITY_NAME;
        String CATEGORY;
        String BUILDING_NAME;
        String LOCATION_CODE;
        String UNIT_TYPE;
        String UNIT_MODEL;
        String ORDER_STATUS;
        String INCIDENT_TYPE;
        String ALDAR_SERVICE_AGENT;
        Date ORDER_DATE;
        Decimal NET_AMOUNT;
        String SALES_ORDER_ID;
        String ALDAR_DLP_AGENT;
        String CUST_ACCOUNT_ID;
        Date REC_UPDATE_DATE;
        String EMIRATES_ID;
        String TRIGGER_SOURCE;
        String TRIGGER_TOUCHPOINT;
        String ConfigGroup;
        String SFUNITID;
        String CASEID;

        public QualtricsCaseWrapper(Case caseRecord){
            boolean isTenant = (caseRecord.CustomerType__c == Constants.CASE_CUSTOMER_TENANT ||  caseRecord.CustomerType__c == Constants.CASE_CUSTOMER_VISITOR);
            RECID = caseRecord.Id +'#'+ caseRecord.CaseNumber;
            firstName =isTenant?caseRecord.SuppliedName : caseRecord.Account.FirstName ;
            if(!isTenant){
               lastName =caseRecord.Account.LastName;  
            }
            email =isTenant? caseRecord.SuppliedEmail: caseRecord.Account.PersonEmail ;
            mobileNo =isTenant? caseRecord.SuppliedPhone: caseRecord.Account.MobileCountryCode__pc + caseRecord.Account.MobilePhone__pc;
            TITLE =isTenant?'' :caseRecord.Account.PersonTitle ;
            COMPLETE_PARTY_NAME =isTenant?caseRecord.SuppliedName : caseRecord.Account.Name ;
            
            GENDER = caseRecord.Account.Gender__pc;
            PREFERRED_CONTACT_METHOD='';
            
            PARTY_ID=caseRecord.AccountId;
            PROPERTY_NAME = caseRecord.Unit__r.Project__r.Name;
            COMMUNITY_NAME = caseRecord.Unit__r.CommunityName__c;
            CATEGORY = caseRecord.SubVertical__c ;
            BUILDING_NAME = caseRecord.Unit__r.BuildingSectionName__r.Name;
            LOCATION_CODE = caseRecord.Unit__r.Name;
            UNIT_TYPE = caseRecord.Unit__r.UnitType__c;
           
            INCIDENT_TYPE= caseRecord.CaseCategory__c;
            
            CUST_ACCOUNT_ID = caseRecord.AccountId;
            REC_UPDATE_DATE = caseRecord.lastModifiedDate.date();
            SFUNITID = caseRecord.Unit__c;
            ConfigGroup='PRODALServiceExp';
            TRIGGER_SOURCE='SALESFORCE';
            TRIGGER_TOUCHPOINT='Closed';
            CASEID=caseRecord.Id;

            if(caseRecord.Vertical__c == Constants.DLP_SUB_VERTICAL){
                NATIONALITY = caseRecord.Account.Nationality__pc ;
                COUNTRY_OF_RESIDENCE = caseRecord.Account.CountryOfResidence__pc ;   
                CITY = caseRecord.Account.PersonMailingCity ;
                POSTAL_CODE = caseRecord.Account.PersonMailingPostalCode ;
                MARITAL_STATUS = caseRecord.Account.MaritalStatus__pc ;
                DATE_OF_BIRTH = caseRecord.Account.PersonBirthdate ;
                COMPLETE_OTHER_PHONE_NUMBER = caseRecord.Account.MobilePhone__pc ;
                PREFFERED_LANGUAGE_METHOD = caseRecord.Account.LanguagePreference__pc ;
                EMIRATE = '' ;
                NAME_IN_ARABIC = '' ;
                UNIT_MODEL = caseRecord.Unit__r.UnitModel__c ;
                ORDER_STATUS = caseRecord.SalesOrder__r.Status__c ;
                ALDAR_SERVICE_AGENT= caseRecord.Owner.Name ;
                ORDER_DATE = caseRecord.SalesOrder__r.SoldDate__c ;
                NET_AMOUNT = caseRecord.SalesOrder__r.NetAmount__c ;
                SALES_ORDER_ID = caseRecord.SalesOrder__c ;
                ALDAR_DLP_AGENT = caseRecord.Owner.Name ;
                EMIRATES_ID = caseRecord.Account.NationalIdNumber__pc ;
                //Survey details
                ConfigGroup= 'ProdDLPExperience';
                TRIGGER_SOURCE = 'SALESFORCE';
                TRIGGER_TOUCHPOINT= 'DLP Closed';
               
            }
        }

    }
}