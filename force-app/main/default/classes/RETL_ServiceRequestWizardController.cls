/**
 * @File Name : RETL_ServiceRequestWizardController.cls
 * @Description :
 * @Author :
 * @Last Modified By :
 * @Last Modified On : Oct 14, 2025
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | Oct 14, 2025 | Abhijith Damodaran (Protiviti) | Initial Version
 **/
public without sharing class RETL_ServiceRequestWizardController {
    /*
     * @method getCurrentUserDetails()
     * @desc fetch current logged in user details
     *
     * @param {String} base64 - base64 string that represents the file
     * @param {String} filename - full file name with extension, i.e. 'products.csv'
     * @param {String} recordId - Id of the record you want to attach this file to
     *
     * @return {ContentVersion} - returns the created ContentDocumentLink Id if the
     *   upload was successful, otherwise returns null
     */
    @AuraEnabled(cacheable=true)
    public static User getCurrentUserDetails(string contactId) {
        Id currentUserId = UserInfo.getUserId();
        system.debug('currentUserId '+ currentUserId);
        system.debug('contactId'+contactId);
        List<User> userData;
        if( contactId != null ){
            userData =  [
                SELECT Id, Name, Email, UserType, Profile.Name, Profile.UserLicense.Name, ContactId, Contact.AccountId,Contact.RecordType.Name, Contact.Account.CustomerVertical__c,
                Contact.FirstName, Contact.MiddleName, Contact.LastName, Contact.Account.Name, Contact.Account.Role__c, Contact.Account.Email__c, Contact.Account.MobileCountryCode__c,
                Contact.Account.MobileNumber1__c, Contact.Account.MobileNumber__c, Contact.Account.BillingStreet, Contact.Account.BillingCity, Contact.Account.BillingPostalCode, Contact.Account.BillingState, Contact.Account.RegistrationIssueDate__c,
                Contact.Account.RegistrationNumber__c, Contact.Account.RegistrationExpiryDate__c, Contact.Account.PlaceOfRegistration__c, Contact.Account.RETL_LicenseIssuedCity__c,
                Contact.Account.UAEVATRegisterNumber__c, Contact.Account.P_O_Box__c, Contact.Account.Fax, Contact.Salutation, Contact.MobileCountryCode__c, Contact.MobilePhone__c, Contact.MobilePhone,
                Contact.Email, Contact.MailingStreet, Contact.MailingCity, Contact.MailingPostalCode, Contact.CountryOfResidence__c, Contact.CustomerLocation__c, Contact.NationalIdExpiryDate__c,
                Contact.NationalIdNumber__c, Contact.PassportNumber__c, Contact.PlaceofIssue__c, Contact.PassportIssueDate__c, Contact.PassportExpiryDate__c, Contact.RETL_Visa_Issue_Location__c,
                Contact.VisaUIDNo__c, Contact.RETL_Visa_Issue_Date__c, Contact.VisaExpiryDate__c, Contact.Nationality__c
                FROM User
                WHERE ContactId =: contactId
                LIMIT 1
            ];
        }
        else{
            userData =  [
                SELECT Id, Name, Email, UserType, Profile.Name, Profile.UserLicense.Name, ContactId, Contact.AccountId,Contact.RecordType.Name, Contact.Account.CustomerVertical__c,
                Contact.FirstName, Contact.MiddleName, Contact.LastName, Contact.Account.Name, Contact.Account.Role__c, Contact.Account.Email__c, Contact.Account.MobileCountryCode__c,
                Contact.Account.MobileNumber1__c, Contact.Account.BillingStreet, Contact.Account.BillingCity, Contact.Account.BillingPostalCode, Contact.Account.BillingState,
                
                Contact.Account.RegistrationNumber__c, Contact.Account.RegistrationExpiryDate__c, Contact.Account.PlaceOfRegistration__c, Contact.Account.RETL_LicenseIssuedCity__c,
                Contact.Account.UAEVATRegisterNumber__c, Contact.Account.P_O_Box__c, Contact.Account.Fax, Contact.Salutation, Contact.MobileCountryCode__c, Contact.MobilePhone__c, Contact.MobilePhone,
                Contact.Email, Contact.MailingStreet, Contact.MailingCity, Contact.MailingPostalCode, Contact.CountryOfResidence__c, Contact.CustomerLocation__c, Contact.NationalIdExpiryDate__c,
                Contact.NationalIdNumber__c
                FROM User
                WHERE Id =: currentUserId
                LIMIT 1
            ];
        }
        return userData[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<StoreWrapper> getStores(Id contactId) {
        //Set<Id> contactList = new Set<Id>();
        Set<Id> accountList = new Set<Id>();
        Set<Id> leaseList = new Set<Id>();
        if( contactId != null){

            for(RETL_Contact_Role__c contactRole : [
                Select Id, RETL_Contact_role__c, RETL_Contact__c, RETL_Account_Name__c,RETL_Lease__c
                From RETL_Contact_Role__c
                Where RETL_Contact__c =:contactId
            ]){
                if(contactRole.RETL_Account_Name__c != null){
                    accountList.add(contactRole.RETL_Account_Name__c);
                }
                if(contactRole.RETL_Lease__c != null){
                    leaseList.add(contactRole.RETL_Lease__c);
                }
            }
        }
        List<StoreWrapper> stores = new List<StoreWrapper>();
        List<OrderItem> orderItems = [
            SELECT Id, RETL_Area__c, RETL_Building__c, RETL_Unit__c,RETL_UnitType__c, OrderId, RETL_MoveOutDate__c, Order.RETL_Property_Description__c, 
            Order.RETL_Brand__r.Name,Order.RETL_Property_Name__c	, RETL_MoveInDate__c, RETL_Location__c,RETL_Yardi_Id__c, RETL_Floor__c, EndDate,RETL_PropertyName__c
            FROM OrderItem
            WHERE ( OrderId IN : leaseList OR Order.AccountId IN: accountList )
            AND Order.RETL_Status__c = 'Current'
        ];
        for (OrderItem oi : orderItems) {
            StoreWrapper sw = new StoreWrapper();
            sw.orderItemId   = oi.Id;
            sw.leaseId       = oi.OrderId;
            sw.propertyName  = (oi.Order.RETL_Property_Description__c != null)? oi.Order.RETL_Property_Description__c : oi.Order.RETL_Property_Name__c;
            sw.unit          = oi.RETL_Unit__c;
            sw.brandName     = (oi.Order.RETL_Brand__r.Name != null) ? oi.Order.RETL_Brand__r.Name : '';
            stores.add(sw);
        }
        return stores;
    }
	
    @AuraEnabled(cacheable=true)
    public static List<Retail_Unit__c> getAllProperties(String keyword) {
        List<String> propertyNames = new List<String>();
        String searchKey = keyword != null?'%' + keyword.trim() + '%':'';
        
        Map<String, Retail_Unit__c> uniquePropertyMap = new Map<String,Retail_Unit__c>();
        List<Retail_Unit__c> uniquePropertySet = new List<Retail_Unit__c>();
        List<Retail_Unit__c> propertyDetails = [
            SELECT Id, Property_Name__c, Floor__c, Unit_Location__c,Property_Code__c  
            FROM Retail_Unit__c 
            WHERE Property_Name__c != null AND Property_Name__c LIKE :searchKey
            ];
        for( Retail_Unit__c property:propertyDetails){
            if(!uniquePropertyMap.ContainsKey(property.Property_Code__c)){
                uniquePropertyMap.put(property.Property_Code__c, property);
                uniquePropertySet.add(property);
            }
        }
        return uniquePropertySet;
    }
    
    @AuraEnabled(Cacheable=true)
    public static List<Retail_Unit__c> searchRetailUnits(string propertyCode){
        List<Retail_Unit__c> propertyUnits = [
            								  SELECT Id, Property_Name__c, Unit_Code__c, Property_Code__c 
                                              FROM Retail_Unit__c
            								  WHERE Property_Code__c =: propertyCode
        									];
        return propertyUnits;
    }
    
    @AuraEnabled()
    public static String getOrderItemFromContractorSelection(String propertyCode){
        List<OrderItem> orderItems = [
            SELECT Id, RETL_Area__c, RETL_Building__c, RETL_Unit__c,RETL_UnitType__c, OrderId, RETL_MoveOutDate__c, Order.RETL_Property_Description__c, 
            Order.RETL_Brand__r.Name,Order.RETL_Property_Name__c	, RETL_MoveInDate__c, RETL_Location__c,RETL_Yardi_Id__c, RETL_Floor__c, EndDate,RETL_PropertyName__c
            FROM OrderItem
            WHERE Order.RETL_Property_Name__c =: propertyCode
            AND Order.RETL_Status__c = 'Current'
        ];
        string orderId;
        if( !orderItems.isEmpty()){
            for(OrderItem oi: orderItems){
                orderId = oi.OrderId;
            }
        }
        return orderId;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<RETL_SR_Master__c> getAllServiceData(String persona) {
        String sanitizedVal = String.escapeSingleQuotes(persona);
        String objName ='RETL_SR_Master__c';
        String fldName = 'RETL_Persona__c';
    String query = 'SELECT Id, RETL_Category__c, RETL_Sub_Category__c, RETL_Service_Type__c,RETL_Persona__c, RETL_Content__c, RETL_Total_Steps__c, RETL_Next_Step_Title__c, RETL_Step_Number__c, RETL_Display_Order__c FROM ' + objName + ' WHERE ' + fldName + ' INCLUDES (\'' + sanitizedVal + '\')';
    return Database.query(query);
       /* return [
            SELECT Id, RETL_Category__c, RETL_Sub_Category__c, RETL_Service_Type__c,RETL_Persona__c,
                RETL_Content__c, RETL_Total_Steps__c, RETL_Next_Step_Title__c, RETL_Step_Number__c, RETL_Display_Order__c
            FROM RETL_SR_Master__c 
            WHERE RETL_Active__c = true AND RETL_Vertical__c Like '%Retail%' Order By RETL_Display_Order__c ASC Nulls Last
        ];*/
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String,Object>>> getSectionFieldMap( String category, String subCategory, String serviceType ) {
        if (category == 'General Request') {
            subCategory = 'General';
        }

        List<RETL_SR_Field_Mapping__c> fieldMappings = [
            SELECT RETL_SR_Section__r.Name,
                RETL_SR_Section__r.RETL_Step_Title__c,
                RETL_SR_Section__r.RETL_Visible__c,
                RETL_SR_Section__r.RETL_SR_Section_Title__c,
                RETL_SR_Section__r.RETL_Display_Order__c,
                RETL_Form_Field_Name__c,
                RETL_Data_Type__c,
                RETL_SF_Field_Name__c,
                RETL_SF_Object_Name__c,
                RETL_Picklist_Values__c,
                RETL_Display_Order__c,
                RETL_Required__c,
                RETL_SR_Section__r.RETL_Step_Number__c,
                RETL_isPair__c,
                RETL_Pair_Order__c,
                RETL_Controlled_By__c,
                RETL_Validations__c,
                RETL_Parent_Picklist_Value__c,
                RETL_Content__c,
                RETL_SR_Character_Limit__c,
                RETL_SR_Section__r.RETL_SR_Master__r.RETL_Total_Steps__c,
                RETL_SR_Section__r.RETL_SR_Master__r.RETL_Next_Step_Title__c
            FROM RETL_SR_Field_Mapping__c
            WHERE RETL_SR_Section__r.RETL_SR_Master__r.RETL_Category__c = :category
            AND RETL_SR_Section__r.RETL_SR_Master__r.RETL_Sub_Category__c = :subCategory
            AND RETL_SR_Section__r.RETL_SR_Master__r.RETL_Service_Type__c = :serviceType
            AND RETL_SR_Section__r.RETL_SR_Section_Title__c != null
            AND RETL_Is_Active__c =  true
            ORDER BY RETL_Display_Order__c
        ];

        Map<String, List<Map<String,Object>>> sectionFieldMap = new Map<String, List<Map<String,Object>>>();

        //  Step 3: Build final response

        for (RETL_SR_Field_Mapping__c fm : fieldMappings) {
            if (!sectionFieldMap.containsKey(fm.RETL_SR_Section__r.RETL_SR_Section_Title__c)) {
                sectionFieldMap.put(fm.RETL_SR_Section__r.RETL_SR_Section_Title__c, new List<Map<String,Object>>());
            }
            sectionFieldMap.get(fm.RETL_SR_Section__r.RETL_SR_Section_Title__c).add(buildFieldMap(fm));
        }
        return sectionFieldMap;
    }

    /**
     * Build a normal single field map
     */
    @TestVisible
    private static Map<String,Object> buildFieldMap(RETL_SR_Field_Mapping__c fm) {
        return new Map<String,Object>{
            'sectionVisible' => String.valueOf(fm.RETL_SR_Section__r.RETL_Visible__c),
            'formLabel'      => fm.RETL_Form_Field_Name__c,
            'sfFieldName'    => fm.RETL_SF_Field_Name__c,
            'sfObjectName'   => fm.RETL_SF_Object_Name__c,
            'dataType'       => fm.RETL_Data_Type__c,
            'picklistVals'   => fm.RETL_Picklist_Values__c,
            'displayOrder'   => String.ValueOf(fm.RETL_Display_Order__c),
            'required'       => String.ValueOf(fm.RETL_Required__c),
            'sectionOrder'   => String.valueOf(fm.RETL_SR_Section__r.RETL_Display_Order__c),
            'stepNumber'     => String.valueOf(fm.RETL_SR_Section__r.RETL_Step_Number__c),
            'isPair'         => String.valueOf(fm.RETL_isPair__c),
            'pairOrder'      => String.valueOf(fm.RETL_Pair_Order__c),
            'controlledBy'   => fm.RETL_Controlled_By__c,
            'parentPicklistValue'=> fm.RETL_Parent_Picklist_Value__c,
            'validations'    => fm.RETL_Validations__c,
            'stepTitle'      => fm.RETL_SR_Section__r.RETL_Step_Title__c,
            'fieldLimit'     => fm.RETL_SR_Character_Limit__c != null ? String.valueOf(fm.RETL_SR_Character_Limit__c) : '255',
            'errorMessage'   => '',
            'uniqueIdentifier' => fm.RETL_SR_Section__r.RETL_SR_Section_Title__c + '-'+fm.RETL_Form_Field_Name__c+'-'+'-'+fm.RETL_SF_Field_Name__c+'-'+fm.RETL_SF_Object_Name__c+'-'+String.valueOf(fm.RETL_SR_Section__r.RETL_Step_Number__c)
        };
            }
    
    @AuraEnabled(cacheable=true)
    public static String getFileUploadEndpoint() {
        String domain = URL.getOrgDomainUrl().toExternalForm();
        system.debug('domain'+domain);
        //String base = domain + '/services/apexrest/FileUpload';
        return domain + '/services/apexrest/FileUpload';
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getDocument(String contactId, String accountId){
        system.debug('contactId'+contactId + ' accountId'+accountId);
        
        List<Document__c> docList = [
            SELECT Id, Name, Account__c, Contact__c, DocumentType__c, CreatedDate
            FROM Document__c
            WHERE Account__c = :accountId 
            OR Contact__c = :contactId
            ORDER BY DocumentType__c, CreatedDate DESC
        ];
        
        // Map to store only latest record per DocumentType
        Map<String, Document__c> latestDocByType = new Map<String, Document__c>();
        
        for (Document__c doc : docList) {
            if (!latestDocByType.containsKey(doc.DocumentType__c)) {
                latestDocByType.put(doc.DocumentType__c, doc);
            }
        }
        
        // Final list of latest docs
        List<Document__c> latestDocs = latestDocByType.values();
        
        Map<Id, DocumentWrapper> mapDoc = new Map<Id, DocumentWrapper>();
        
        for(Document__c d : latestDocs){
            DocumentWrapper w = new DocumentWrapper();
            w.contentDocumentId = d.Id;
            w.documentType = d.DocumentType__c;
            w.label = d.Name;    
            mapDoc.put(d.Id, w);
        }
        
        
        // Fetch ContentDocumentLink for these Document__c records
        if( !mapDoc.isEmpty()){
            List<ContentDocumentLink> links = [
                SELECT Id, ContentDocumentId, LinkedEntityId,
                ContentDocument.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :mapDoc.keySet()
            ];
            if( !links.isEmpty()){
                for(ContentDocumentLink link : links){
                    if(mapDoc.containsKey(link.LinkedEntityId)){
                        mapDoc.get(link.LinkedEntityId).fileName = link.ContentDocument.Title;
                    }
                }
                return mapDoc.values();
            }
        }
        return new list<DocumentWrapper>();
    }
    
    public class DocumentWrapper {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String documentType;
        @AuraEnabled public String fileName;  
        @AuraEnabled public String label;     
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getCountryPicklistValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = Contact.Nationality__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            values.add(entry.getLabel());
        }
        system.debug('values'+values);
        return values;
    }
	
    @AuraEnabled(cacheable=true)
    public static String  getTenantPortalSetting() {
        RETL_Tenant_Portal_Setting__mdt record = [
            SELECT Value__c
            FROM RETL_Tenant_Portal_Setting__mdt WHERE DeveloperName = 'File_Size_Limit' limit 1
        ];
        return record.Value__c;
    }
    

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccount(Id accountId) {
        if (accountId == null) {
            return new List<Contact>();
        }
        system.debug('AccountId  '+accountId);
        return [
              SELECT Id, Name
              FROM Contact
              WHERE Id IN (
                SELECT RETL_Contact__c
                FROM RETL_Contact_Role__c
                WHERE  RETL_Account_Name__c =: accountId OR RETL_Lease__r.AccountId =: accountId
              )
              ORDER BY Name
        ];
    }

    @AuraEnabled
    public static caseCreationWrapper createRecord(
        String groupedFieldValuesJson,
    String category,
    String subCategory,
    String serviceType,
    String orderId,
    String contactId,
    String storeName
    ) {
        GroupedFieldWrapper groupedFieldValues =
            (GroupedFieldWrapper) JSON.deserialize(groupedFieldValuesJson, GroupedFieldWrapper.class);
        system.debug('groupedFieldValuesJson'+groupedFieldValuesJson);
        caseCreationWrapper cw = new caseCreationWrapper();
        if( category == 'General Request'){
            subCategory = 'General';
        }
        try{
            //  Create Case
            Case newCase = createCase(groupedFieldValues, category, subCategory, serviceType, orderId, contactId);
            newCase.RETL_SR_Unit_Number__c=storeName;
            insert newCase;
            List<External_Files__c> files = new List<External_Files__c>();
            //  Contractors
            if (!isNotApplicable(groupedFieldValues)) {
                handleContractorDetails(groupedFieldValues.Contractors, newCase);
            }
            
            //  Wrap response
            cw.newCase = [
                SELECT Id, CaseNumber, CaseComments__c, Subject, Description
                FROM Case WHERE Id = :newCase.Id
            ];
            cw.objectsCreated = null;
            cw.fileLinks = new List<String>();
            
            if(category=='NOC' || category=='Work Permit'){
            //  Dynamic child records
            List<SObject> childRecords = createChildRecords(groupedFieldValues, newCase, storeName, category);
            if (!childRecords.isEmpty()) {
                system.debug('childRecords'+childRecords);
                insert childRecords;
                newCase.RETL_SR_Additional_Info__c = childRecords[0].Id;
            }

            update newCase;
            cw.objectsCreated = childRecords;
            }
            
        }
        catch(exception e){
            system.debug('Case creation failed : '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return cw;
    }

    private static Case createCase(
        GroupedFieldWrapper groupedFieldValues,
    String category,
    String subCategory,
    String serviceType,
    String orderId,
    String contactId
    ) {
        if( category == 'General Request'){
            subCategory ='General';
        }
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SR-Retail').getRecordTypeId();
        List<Group> supportQueues = [SELECT Id FROM Group WHERE DeveloperName = 'Retail_SR_Queue' AND Type = 'Queue' LIMIT 1];
        Id queueId = !supportQueues.isEmpty() ? supportQueues[0].Id:Null;
        List<Entitlement> entitlements = [SELECT Id FROM Entitlement
                                            WHERE RETL_SR_Category__c =:category
                                            AND RETL_SR_Sub_Category__c =:subCategory
                                            AND RETL_SR_Service_Type__c=:serviceType
                                            LIMIT 1];
        orderId = orderId != '' && orderId != null?orderId: null;
        system.debug('orderId==>'+orderId);
        List<Order> leases = new List<Order>();
        if( orderId != null){
            leases = [
                SELECT Id, RETL_Property_Name__c, RETL_Property_Description__c, AccountId
                FROM Order
                WHERE Id=:orderId AND RETL_Status__c = 'Current'
                LIMIT 1
            ];
        }
        
		Order lease = !leases.isEmpty() ? leases[0] : null;
        Case c = new Case(
            Origin = 'Customer App',
            Status = 'New',
            AccountId = (lease != null && lease.AccountId != null) ? lease.AccountId : null,
            ContactId = contactId,
            Vertical__c = 'Aldar Retail',
            SubVertical__c = 'Retail',
            ECSS_CompanyOptions__c = 'Retail',
            Requested_Date__c = System.now(),
            EntitlementId = (entitlements.size() > 0 ? entitlements[0].Id : null),
            RETL_SR_Order__c = lease != null ?lease.Id:null,
            RETL_SR_Property_Name__c = (lease != null && lease.RETL_Property_Description__c != null ) ? lease.RETL_Property_Description__c : lease != null && lease.RETL_Property_Name__c != null ?lease.RETL_Property_Name__c: '',
            RETL_SR_Category__c = category,
            RETL_SR_Sub_Category__c = subCategory,
            RETL_SR_Service_Type__c = serviceType,
            RecordTypeId  = recordTypeId,
            Priority = 'P3'
        );
        if( queueId != null){
            c.OwnerId = queueId;
        }
        applyDynamicFields(groupedFieldValues.Case1, c);
        //  Special handling for subject
        if(c.RETL_SR_Category__c == 'NOC' || c.RETL_SR_Category__c == 'Work Permit') {
            c.Subject =
                (c.SubVertical__c != null ? c.SubVertical__c : '') + ' - ' +
                (c.RETL_SR_Category__c != null ? c.RETL_SR_Category__c : '') + ' - ' +
                (c.RETL_SR_Sub_Category__c != null ? c.RETL_SR_Sub_Category__c : '') + ' - ' +
                (c.RETL_SR_Service_Type__c != null ? c.RETL_SR_Service_Type__c : '');
        }
        Id queueIdFromMdt = assignQueueFromMDT(c);
        if(queueIdFromMdt != null){
            c.OwnerId = queueIdFromMdt;
        }
        
        List<RETL_SR_Master__c> srMaster = [SELECT Id, RETL_Category__c, RETL_Sub_Category__c, RETL_Service_Type__c, RETL_Yardi_Work_Order_Category__c, RETL_Yardi_Work_Order_Sub_Category__c FROM RETL_SR_Master__c
                                      WHERE 
                                      RETL_Category__c=:category 
                                      AND RETL_Sub_Category__c=:subCategory
                                      AND RETL_Service_Type__c =: serviceType
                                      LIMIT 1];
        if(srMaster.size()>0 && srMaster[0].RETL_Yardi_Work_Order_Category__c!=null && srMaster[0].RETL_Yardi_Work_Order_Sub_Category__c !=null ){
            
            c.RETL_Yardi_Work_Order_Category__c = srMaster[0].RETL_Yardi_Work_Order_Category__c;
            c.RETL_Yardi_Work_Order_Sub_Category__c =srMaster[0].RETL_Yardi_Work_Order_Sub_Category__c;
        }
        return c;
    }

    private static Id assignQueueFromMDT(Case newCase) {
        String cat;
        if(newCase.RETL_SR_Category__c == 'General Request'){
            cat = newCase.RETL_SR_Service_Type__c;
        }else{
            cat = newCase.RETL_SR_Category__c;
        }
        List<Retail_SR_Case_Ownership__mdt> mdtRecords = [
            											    SELECT Queue_Name__c
                                                            FROM Retail_SR_Case_Ownership__mdt
                                                            WHERE MasterLabel = :cat LIMIT 1
                                                         ];
        Id queueId;
        String queueName;
        if (!mdtRecords.isEmpty()) {
            queueName = mdtRecords[0].Queue_Name__c;
            List<Group> supportQueues = [SELECT Id FROM Group WHERE DeveloperName = :queueName AND Type = 'Queue' LIMIT 1];
            queueId = supportQueues[0].Id;
        }
        system.debug('QueueName : '+queueName);
        return queueId;
    }

    // merged dynamic field setter
    private static void applyDynamicFields(Map<String, Object> fieldsMap, SObject target) {
        if (fieldsMap == null) return;
        for (String fieldName : fieldsMap.keySet()) {
            Object rawValue = fieldsMap.get(fieldName);
            if (rawValue == null || String.valueOf(rawValue).trim() == '') continue;
            try {
                SObjectField sField = target.getSObjectType().getDescribe().fields.getMap().get(fieldName);
                if (sField == null) continue;
                Schema.DescribeFieldResult fieldDesc = sField.getDescribe();
                Schema.DisplayType dtype = fieldDesc.getType();
                //  Convert based on Salesforce datatype
                if( dtype == Schema.DisplayType.Time && rawValue instanceof String){
                    rawValue = convertStringToTime((String)rawValue);
                }
                else if (dtype == Schema.DisplayType.DateTime && rawValue instanceof String) {
                    rawValue = Datetime.valueOfGMT(((String) rawValue).replace('T', ' ') + ':00');
                } else if (dtype == Schema.DisplayType.Date && rawValue instanceof String) {
                    rawValue = Date.valueOf((String) rawValue);
                } else if (dtype == Schema.DisplayType.Boolean) {
                    rawValue = (rawValue instanceof Boolean)
                        ? rawValue
                        : Boolean.valueOf(String.valueOf(rawValue));
                } else if (dtype == Schema.DisplayType.Integer) {
                    rawValue = (rawValue instanceof Integer)
                        ? rawValue
                        : Integer.valueOf(String.valueOf(rawValue));
                } else if (dtype == Schema.DisplayType.Double
                || dtype == Schema.DisplayType.Currency
                || dtype == Schema.DisplayType.Percent) {
                    rawValue = (rawValue instanceof Decimal)
                        ? rawValue
                        : Decimal.valueOf(String.valueOf(rawValue));
                } else if (dtype == Schema.DisplayType.String
                || dtype == Schema.DisplayType.TextArea
                    || dtype == Schema.DisplayType.EncryptedString
                    || dtype == Schema.DisplayType.Phone
                    || dtype == Schema.DisplayType.Email
                    || dtype == Schema.DisplayType.Url
                    || dtype == Schema.DisplayType.Picklist
                || dtype == Schema.DisplayType.MultiPicklist) {
                    rawValue = String.valueOf(rawValue);
                } else if (dtype == Schema.DisplayType.Id) {
                    rawValue = (rawValue instanceof Id)
                        ? rawValue
                        : String.valueOf(rawValue);
                }
                target.put(fieldName, rawValue);
            } catch (Exception e) {
                System.debug(' Could not set ' + fieldName + ' → ' + e.getMessage());
            }
        }
    }


    private static void handleContractorDetails(List<ContractorWrapper> contractors, Case newCase) {
        if (contractors == null || contractors.isEmpty()) return;

        List<SObject> toInsert = new List<SObject>();

        for (ContractorWrapper cw : contractors) {
            Account acc = upsertContractorAccount(cw.Account);
            Contact con = upsertContractorContact(cw.Contact, acc);
            
            if (acc != null || con != null) {
                toInsert.add(new RETL_Contractor_Case_Linkage__c(
                    RETL_Contractor__c = acc.Id,
                    RETL_Contractor_Contact__c = con != null ?con.Id:null,
                    RETL_Case__c = newCase.Id,
                    RETL_Is_Responsible_Person__c = cw.isResponsible != null? Boolean.valueOf(String.valueOf(cw.isResponsible)): false
                ));
            }
        }
        if (!toInsert.isEmpty()) insert toInsert;
    }

    @AuraEnabled()
    public static Map<String, Object> uploadDocuments( String filesData, String parentId, String caseCommentId){
        system.debug('inside uploadDocuments');
        System.debug('Current Heap Size: ' + Limits.getHeapSize());
        try{
                return RETL_SRDocumentHandler.handleDocuments( filesData,  parentId,  caseCommentId);
            }
        catch (Exception e) {
            System.debug('Document Upload failed : ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException('Document upload failed: ' + e.getMessage());
        }
        // return new Map<String, Object>();
    }

    private static Account upsertContractorAccount(Map<String,Object> accFields) {
            if (accFields == null) {
                return null;
            }
            String accName = (String) accFields.get('Name');
            String nationalId = (String)accFields.get('RegistrationNumber__c');
        	String mobileNumber = (String)accFields.get('MobileNumber__c');
        	String tradeLicenseIissuedCity = (String)accFields.get('RETL_LicenseIssuedCity__c');
        	String email = (String)accFields.get('EmailAddress__c');
            List<Account> accList = new List<Account>();
            Account acc;
            if (String.isNotBlank(accName)) {
                accList = [SELECT Id, Name FROM Account WHERE RegistrationNumber__c =:nationalId LIMIT 1];
            }
            if (accList.isEmpty()) {
                acc = new Account();
                acc.Type = 'Contractor';
                acc.CustomerVertical__c = 'Retail';
                acc.BillingCountry = 'United Arab Emirates';
                acc.RegistrationNumber__c = nationalId;
                acc.MobileNumber1__c = mobileNumber.replaceFirst('^971-?', '');
                acc.MobileCountryCode__c = '971';
                acc.PlaceOfRegistration__c = tradeLicenseIissuedCity;
                acc.Email__c = email;
            } else {
                acc = accList[0];
                acc.Name = acc.Name + 'updated';
            }
            applyDynamicFields(accFields, acc);
        	system.debug('acc'+acc);
            upsert acc;
            return acc;
        }

        private static Contact upsertContractorContact(Map<String,Object> conFields, Account acc) {
            if (conFields == null || acc == null) {
                return null;
            }
            String email = (String) conFields.get('Email');
            String emiratesId = (String) conFields.get('NationalIdNumber__c');
            String MobilePhone = (String) conFields.get('MobilePhone');
            Contact con;
            //
			List<Contact> cons = new List<Contact>();
            if (String.isNotBlank(email)) {
                cons = [SELECT Id FROM Contact WHERE Email = :email OR  NationalIdNumber__c = :emiratesId LIMIT 1];
                //con = cons.isEmpty() ? new Contact(AccountId=acc.Id) : cons[0];
            } else {
                con = new Contact(AccountId=acc.Id);
                con.RecordTypeId =  Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contractor').getRecordTypeId();
            }
            if( cons.isEmpty() ){
                con = new Contact();
                con.AccountId=acc.Id;
                con.MobilePhone__c = MobilePhone.replaceFirst('^971-?', '');
                con.MobileCountryCode__c = '971';
            }
            else{
                con = cons[0];
            }
            applyDynamicFields(conFields, con);
            upsert con;
            return con;
        }

        private static List<SObject> createChildRecords(GroupedFieldWrapper groupedFieldValues, Case newCase, String storeName, String category) {
            List<SObject> recordsToInsert = new List<SObject>();
            if(groupedFieldValues.AdditionalInfo == null){
                groupedFieldValues.AdditionalInfo = new Map<String,string>();
            }
            if (groupedFieldValues.AdditionalInfo != null) {
                system.debug('groupedFieldValues.AdditionalInfo '+groupedFieldValues.AdditionalInfo );
                RETL_SR_Additional_Info__c newObj = new RETL_SR_Additional_Info__c();
                newObj.put('RETL_Case__c', newCase.Id);
                newObj.put('RETL_Unit_No__c',storeName);
                applyDynamicFields(groupedFieldValues.AdditionalInfo, newObj);
                system.debug('newObj'+newObj);
                recordsToInsert.add(newObj);
            }
            return recordsToInsert;
        }
        @TestVisible
        private static Time convertStringToTime(String timeString){
            List<String> timeParts = timeString.split(':');
            Time convertedTime;
            if (timeParts.size() == 3) {
                Integer hour = Integer.valueOf(timeParts[0]);
                Integer minute = Integer.valueOf(timeParts[1]);
                Integer second = Integer.valueOf(timeParts[2]);
                convertedTime = Time.newInstance(hour, minute, second, 0); // hour, minute, second, millisecond
                System.debug('Converted Time: ' + convertedTime);
                return convertedTime;
            }
            return convertedTime;
        }

        private static Boolean isNotApplicable(GroupedFieldWrapper groupedFieldValues) {
            if (groupedFieldValues == null) return false;

            if (groupedFieldValues.AdditionalInfo != null
                && groupedFieldValues.AdditionalInfo.containsKey('RETL_Not_Applicable__c')
            && (groupedFieldValues.Contractors == null || groupedFieldValues.Contractors.isEmpty())) {

                Object val = groupedFieldValues.AdditionalInfo.get('RETL_Not_Applicable__c');
                return val instanceof Boolean ? (Boolean)val : Boolean.valueOf(String.valueOf(val));
            }
            return false;
        }

        // Wrappers

        public class StoreWrapper {
            @AuraEnabled public Id orderItemId;
            @AuraEnabled public Id leaseId;
            @AuraEnabled public String propertyName;
            @AuraEnabled public String unit;
            @AuraEnabled public String brandName;
        }

        public class ContractorWrapper {
            @AuraEnabled public Map<String,string> Account;
            @AuraEnabled public Map<String,string> Contact;
            @AuraEnabled public String isResponsible;
        }
        public class GroupedFieldWrapper {
            @AuraEnabled public Map<String,string> Case1;
            @AuraEnabled public Map<String,string> AdditionalInfo;
            @AuraEnabled public List<ContractorWrapper> Contractors;
            @AuraEnabled public List<RETL_SRDocumentHandler.DocumentWrapper> Documents;
        }
        public class caseCreationWrapper {
            @AuraEnabled public Case newCase;
            @AuraEnabled public List<SObject> objectsCreated;
            @AuraEnabled public List<String> fileLinks;
        }

}