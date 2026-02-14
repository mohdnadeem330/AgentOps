public without sharing class RETL_TenantRequestController {

    @AuraEnabled(cacheable=false)
    public static List<Case> getMyRequests(String contactId) {
        Boolean isContractor = false;
        if (contactId == null) {
            Id currentUserId = UserInfo.getUserId();
            List<User> user = [SELECT Id, Name, Email, ContactId, Contact.Account.Type
                            FROM User
                            WHERE Id = :currentUserId
                            LIMIT 1];
            //String contactId;
            if(!user.isEmpty()){
                contactId = user[0].ContactId;
                if( User[0].Contact.Account.Type == 'Contractor'){
                    isContractor = true;
                }
            }
        }

        Set<Id> contactListToCheck = new Set<Id>();
        List<Id> caseContratorLinkageIds = new List<Id>();
        if(contactId != null){
            Set<Id> accountList = new Set<Id>();
            Set<Id> leaseList = new Set<Id>();
            contactListToCheck.add(contactId);
            for(RETL_Contact_Role__c contactRole : [
                									Select Id, RETL_Contact_role__c, RETL_Contact__c, RETL_Account_Name__c,RETL_Lease__c
                								    From RETL_Contact_Role__c
                									Where RETL_Contact__c =:contactId
            									   ]){
                if( contactRole.RETL_Contact_role__c =='Finance/Billing Manager'|| contactRole.RETL_Contact_role__c =='Admin' ||contactRole.RETL_Contact_role__c =='Leasing Manager'){
                    if(contactRole.RETL_Account_Name__c != null){
                        accountList.add(contactRole.RETL_Account_Name__c);
                    }
                    if(contactRole.RETL_Lease__c != null){
                        leaseList.add(contactRole.RETL_Lease__c);
                    }
                }
                else{
                    contactListToCheck.add(contactId);
                }
            }
            if(!accountList.isEmpty() || !leaseList.isEmpty()){
                List<RETL_Contact_Role__c> relatedContact = [
                    Select Id, RETL_Contact_role__c, RETL_Contact__c, RETL_Account_Name__c,RETL_Lease__c
                    From RETL_Contact_Role__c
                    Where RETL_Account_Name__c IN: accountList OR RETL_Lease__c IN: leaseList
                ];
                if(!relatedContact.isEmpty()){
                    for(RETL_Contact_Role__c contactRole:relatedContact){
                        contactListToCheck.add(contactRole.RETL_Contact__c);
                    }
                }
            }
            
            if(isContractor){
                for(RETL_Contractor_Case_Linkage__c  ccl : [Select  RETL_Case__c from RETL_Contractor_Case_Linkage__c Where RETL_Contractor_Contact__c =: contactId ]){
                    caseContratorLinkageIds.add(ccl.RETL_Case__c);
                }
            }
        }
        system.debug('contactListToCheck '+contactListToCheck);
        List<Case> myRequests = [SELECT ID, ContactId, AccountId, CaseNumber, OwnerId, Status, RETL_SR_Type_Of_Request__c, RETL_SR_Category__c, RETL_SR_Service_Type__c, RETL_SR_Sub_Category__c,
                                 CaseComments__c, createdDate, RETL_Store_Name__c, (SELECT Id, RETL_Unit_No__c
                                                                From SR_Additional_Infos__r)
                                 FROM Case
                                 WHERE ContactId IN:contactListToCheck OR Id IN: caseContratorLinkageIds  Order By CreatedDate DESC  ];
        return myRequests;
    }


    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getCaseDetails(String caseId, Boolean includeDocuments, Boolean includeComments, Boolean includeAccordions) {
        if(String.isBlank(caseId)) {
            return null;
        }
        Map<String, Object> caseDetails = new Map<String, Object>();
        List<Case> caseInfos = [
            SELECT Id, CaseNumber, CaseComments__c, AccountId, Account.Name, ContactId, Contact.Name, Status,
            RETL_SR_Additional_Info__c, RETL_SR_Unit_Number__c, CreatedDate,
            Requested_Date__c, Tenant_Name__c, Subject, Description,RETL_SR_Type_Of_Request__c, RETL_Store_Name__c,
            RETL_SR_Sub_Category__c, RETL_SR_Service_Type__c, RETL_SR_Category__c, RETL_Document_Generated__c
            FROM Case WHERE Id = :caseId LIMIT 1
        ];
        if (!caseInfos.isEmpty()) {
            Case caseInfo = caseInfos[0];
            caseDetails.put('case', caseInfo);
            Map<String, List<ExternalFileWrapper>> documentsMap = getCaseDocuments(caseId, caseInfo.RETL_SR_Category__c);
            if (includeDocuments) {
                caseDetails.put('documents', documentsMap);
            }
            if (includeComments) {
                caseDetails.put('comments', getCaseCommentHistory(caseId));
            }
            if (includeAccordions) {
                caseDetails.put('accordions', getAccordions(caseInfo, documentsMap));
            }
        }
        return caseDetails;
    }


    private static List<Map<String, Object>> getAccordions(Case caseRec, Map<String,List<ExternalFileWrapper>> documentsMap) {
        List<Map<String, Object>> accordionsList = new List<Map<String, Object>>();
        Map<String, Object> accordions = new Map<String, Object>();

        List<RETL_SR_Section__c> sections = [
            SELECT Id, RETL_SR_Section_Title__c, RETL_Accordion_Name__c, RETL_Confirmation_And_My_Request__c, RETL_Display_Order__c, RETL_Visible__c,
                (SELECT Id, RETL_Form_Field_Name__c, RETL_SF_Object_Name__c, RETL_SF_Field_Name__c, RETL_Data_Type__c, RETL_Pair_Order__c, RETL_isPair__c, RETL_Display_Order__c
                FROM SR_Field_Mappings__r
                WHERE RETL_Display_Order__c != null AND RETL_Show_in_My_Request_Detail__c = true ORDER BY RETL_Display_Order__c ASC)
            FROM RETL_SR_Section__c
            WHERE RETL_SR_Master__r.RETL_Category__c = :caseRec.RETL_SR_Category__c
            AND RETL_SR_Master__r.RETL_Sub_Category__c = :caseRec.RETL_SR_Sub_Category__c
            AND RETL_SR_Master__r.RETL_Service_Type__c = :caseRec.RETL_SR_Service_Type__c
            // AND RETL_Visible__c = true
            AND RETL_Confirmation_And_My_Request__c = true
            ORDER BY RETL_Display_Order__c ASC
        ];

        // Contractor & Service Accordions
        if( caseRec.RETL_SR_Additional_Info__c != null){
            Map<String,List<Map<String, Object>>>  accordionSectionMap = buildServiceInfoAccordion(caseRec, sections, documentsMap);
            List<Map<String, Object>> serviceInfoDataList = new List<Map<String, Object>>();
            if(!accordionSectionMap.isEmpty()){
                for(String accordionName : accordionSectionMap.keySet()){
                    serviceInfoDataList = accordionSectionMap.get(accordionName);
                    if (!serviceInfoDataList.isEmpty()) {
                        accordionsList.add(new Map<String, Object>{
                            'title' => accordionName,
                                'sections' => serviceInfoDataList
                                });
                    }
                }
            }
            System.debug('serviceInfoDataList== ' + serviceInfoDataList);
            for(RETL_SR_Section__c sec:sections){
                if (sec.RETL_Accordion_Name__c == 'Contractor Details' || sec.RETL_Accordion_Name__c == 'Organizer Details') {
                    List<Map<String, Object>> contractorInfoDataList = buildContractorAccordion(caseRec, new List<RETL_SR_Section__c>{sec}, documentsMap);
                    if (!contractorInfoDataList.isEmpty()) {
                        accordionsList.add(new Map<String, Object>{
                            'title' => sec.RETL_Accordion_Name__c,
                                'sections' => contractorInfoDataList
                                });
                    }
                    System.debug('contractorInfoDataList== ' + contractorInfoDataList);
                }
            }
            
        }
        // accordionsList.add(new Map<String, Object>{'Contractor Details' => buildContractorAccordion(caseRec, sections)});
        //accordions.add(buildServiceInfoAccordion(caseRec, fieldMappings));
        //accordions.put('Service Information', buildServiceInfoAccordion(caseRec, sections));

        System.debug('accordionsList== ' + accordionsList);
        return accordionsList;
    }


    private static Map<String,List<Map<String, Object>>> buildServiceInfoAccordion(Case caseRec, List<RETL_SR_Section__c> sections, Map<String,List<ExternalFileWrapper>> documentsMap) {
        Map<String,List<Map<String, Object>>> accordionSectionMap = new  Map<String,List<Map<String, Object>>>();
        Map<String, Object> serviceData = new Map<String, Object>();
        List<Map<String, Object>> serviceInfoDataList = new List<Map<String, Object>>();
        List<String> customFieldNames = getCustomFieldNames(RETL_SR_Additional_Info__c.SObjectType);
        String soqlFields = String.join(customFieldNames, ',');
        // Use String.escapeSingleQuotes() and add proper spaces
        String soql = 'SELECT Id, Name, ' + soqlFields +
            ' FROM ' + RETL_SR_Additional_Info__c.SObjectType.getDescribe().getName() +
            ' WHERE (Id = \'' + String.escapeSingleQuotes(caseRec.RETL_SR_Additional_Info__c) +
            '\' OR RETL_Case__c = \'' + String.escapeSingleQuotes(caseRec.Id) + '\') LIMIT 1';
        
        System.debug('Final SOQL => ' + soql);
        
        List<RETL_SR_Additional_Info__c> addInfos = new List<RETL_SR_Additional_Info__c>();
        try {
            addInfos = Database.query(soql);
        } catch (Exception e) {
            System.debug(' Error querying SR_Additional_Info object: ' + e.getMessage());
            return accordionSectionMap;
        }
        
       	if (!addInfos.isEmpty()) {
            RETL_SR_Additional_Info__c info = addInfos[0];
            for (RETL_SR_Section__c section : sections) {
                Map<String, Object> sectionData = new Map<String, Object>();
                if (section.RETL_Accordion_Name__c != 'Contractor Details' && section.RETL_Accordion_Name__c != 'Organizer Details') {
                    sectionData.put('sectionName', section.RETL_SR_Section_Title__c);
                    List<Map<String, Object>> fieldDataList = new List<Map<String, Object>>();
                    for (RETL_SR_Field_Mapping__c fm : section.SR_Field_Mappings__r) {
                        Map<String, Object> fieldData = new Map<String, Object>();
                        String value = '';
                        if (fm.RETL_SF_Object_Name__c == 'Case') {
                            value = getFieldValue(fm, caseRec);
                        }
                        if (fm.RETL_SF_Object_Name__c == 'RETL_SR_Additional_Info__c') {
                            value = getFieldValue(fm, info);
                        }
                        if (String.isBlank(value)) {
                            value = 'N/A';
                        }
                        if(fm.RETL_Data_Type__c == 'File' && documentsMap.ContainsKey(fm.RETL_Form_Field_Name__c)){
                            list<ExternalFileWrapper> filesList = documentsMap.get(fm.RETL_Form_Field_Name__c);
                            fieldData.put('filesList',filesList);
                            value = filesList.isEmpty() ? 'N/A' : '';
                        }
                        // fieldData.put(fm.RETL_SF_Field_Name__c, value);
                        fieldData.put('fieldLabel', fm.RETL_Form_Field_Name__c);
                        fieldData.put('fieldValue', value);
                        fieldData.put('fieldDataType', fm.RETL_Data_Type__c);
                        fieldDataList.add(fieldData);
                    }
                    sectionData.put('fields', fieldDataList);
                    //serviceInfoDataList.add(sectionData);
                    if (!accordionSectionMap.containsKey(section.RETL_Accordion_Name__c)) {
                        accordionSectionMap.put(section.RETL_Accordion_Name__c, new List<Map<String, Object>>());
                    }
                    
                    accordionSectionMap.get(section.RETL_Accordion_Name__c).add(sectionData);
                }
            }
        }
        return accordionSectionMap;
    }

    public static List<String> getCustomFieldNames(SObjectType objectType) {
        List<String> customFieldNames = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCustom()) {
                customFieldNames.add(fieldDescribe.getName());
            }
        }
        return customFieldNames;
    }

    // private static List<Map<String, Object>> buildContractorAccordion(Case caseRec, List<RETL_SR_Field_Mapping__c> fieldMappings) {
     @TestVisible
        private static List<Map<String, Object>> buildContractorAccordion(Case caseRec, List<RETL_SR_Section__c> sections, Map<String,List<ExternalFileWrapper>> documentsMap) {
            Map<String,List<Map<String, Object>>> accordionSectionMap = new  Map<String,List<Map<String, Object>>>();
            List<Map<String, Object>> contractorDetailsList = new List<Map<String, Object>>();

            List<RETL_Contractor_Case_Linkage__c> linkages = [
            SELECT Id, Name, RETL_Contractor__r.Name, RETL_Contractor__r.MobileNumber__c,
            RETL_Contractor__r.Email__c, RETL_Contractor__r.RegistrationNumber__c,
            RETL_Contractor__r.RETL_LicenseIssuedCity__c, RETL_Contractor__r.RegistrationExpiryDate__c, RETL_Contractor__r.RegistrationIssueDate__c,
            RETL_Contractor_Contact__r.FirstName, RETL_Contractor_Contact__r.LastName, RETL_Contractor_Contact__r.Email, 
            RETL_Contractor_Contact__r.MobilePhone, RETL_Contractor_Contact__r.Nationality__c, RETL_Contractor_Contact__r.PassportNumber__c, 
            RETL_Contractor_Contact__r.PlaceofIssue__c, RETL_Contractor_Contact__r.PassportIssueDate__c, RETL_Contractor_Contact__r.PassportExpiryDate__c, 
            RETL_Contractor_Contact__r.VisaUIDNo__c, RETL_Contractor_Contact__r.RETL_Visa_Issue_Location__c, RETL_Contractor_Contact__r.VisaExpiryDate__c,
            RETL_Contractor_Contact__r.RETL_Visa_Issue_Date__c, RETL_Contractor_Contact__r.NationalIdNumber__c, RETL_Contractor_Contact__r.NationalIdExpiryDate__c, RETL_Contractor_Contact__r.Description
            FROM RETL_Contractor_Case_Linkage__c WHERE RETL_Case__c = :caseRec.Id
        ];

            List<RETL_SR_Field_Mapping__c> contractorFieldMappings = new List<RETL_SR_Field_Mapping__c>();
            for (RETL_SR_Section__c section : sections) {
                if (section.RETL_Accordion_Name__c == 'Contractor Details' || section.RETL_Accordion_Name__c == 'Organizer Details' ) {
                    for (RETL_SR_Field_Mapping__c fm : section.SR_Field_Mappings__r) {
                        // Just to ensure field mappings are loaded
                        contractorFieldMappings.add(fm);
                    }
                }
            }

            for (RETL_Contractor_Case_Linkage__c linkage : linkages) {
                Map<String, Object> contractorData = new Map<String, Object>();
                contractorData.put('sectionName', linkage.Name);
                List<Map<String, Object>> fieldDataList = new List<Map<String, Object>>();
                for (RETL_SR_Field_Mapping__c fm : contractorFieldMappings) {
                    Map<String, Object> fieldData = new Map<String, Object>();
                    String value = '';
                    if (fm.RETL_SF_Object_Name__c == 'Account') {
                        value = getFieldValue(fm, linkage.RETL_Contractor__r);
                    }
                    if (fm.RETL_SF_Object_Name__c == 'Contact') {
                        value = getFieldValue(fm, linkage.RETL_Contractor_Contact__r);
                    }
                    if (fm.RETL_SF_Object_Name__c == 'RETL_Contractor_Case_Linkage__c') {
                        value = getFieldValue(fm, linkage);
                    }
                    if (String.isBlank(value)) {
                        value = 'N/A';
                    }
                    if(fm.RETL_Data_Type__c == 'File' && documentsMap.ContainsKey(fm.RETL_Form_Field_Name__c)){
                        List<ExternalFileWrapper> filesList = documentsMap.get(fm.RETL_Form_Field_Name__c);
                        fieldData.put('filesList',filesList);
                        value = filesList.isEmpty() ? 'N/A' : '';
                    }
                    // fieldData.put(fm.RETL_SF_Field_Name__c, value);
                    fieldData.put('fieldLabel', fm.RETL_Form_Field_Name__c);
                    fieldData.put('fieldValue', value);
                    fieldData.put('fieldDataType', fm.RETL_Data_Type__c);
                    fieldDataList.add(fieldData);
                }
                contractorData.put('fields', fieldDataList);
                contractorDetailsList.add(contractorData);
                
            }
            return contractorDetailsList;
            // return new Map<String, Object>{
                //     'title' => 'Contractor Details',
                //     'sections' => contractorDetailsList
            // };
        }


        @TestVisible
        private static String getFieldValue(RETL_SR_Field_Mapping__c fm, SObject record) {
            if (record == null || String.isBlank(fm.RETL_SF_Field_Name__c)) {
                return '';
            }
            try {
                if (fm.RETL_SF_Field_Name__c.contains('.')) {
                    system.debug('S checker'+fm.RETL_SF_Field_Name__c);
                    List<String> parts = fm.RETL_SF_Field_Name__c.split('\\.');
                    if (parts.size() == 2) {
                        SObject rel = record.getSObject(parts[0]);
                        system.debug('String.valueOf(rel.get(parts[1])'+String.valueOf(rel.get(parts[1])));
                        return rel != null ? String.valueOf(rel.get(parts[1])) : '';
                    }
                } else {
                    return String.valueOf(record.get(fm.RETL_SF_Field_Name__c));
                }
            } catch (Exception e) {
                System.debug('Error fetching field ' + fm.RETL_SF_Field_Name__c + ': ' + e.getMessage());
            }
            return '';
        }

        public static Map<String, List<ExternalFileWrapper>> getDocuments(String caseId) {
            List<External_Files__c> extFiles = [
            SELECT Id, File_Name__c, External_URL__c,
                Document__r.DocumentType__c,
                Document__r.Case__c,
                RETL_Case_Comment_SF_ID__c
            FROM External_Files__c
            WHERE Document__r.Case__c = :caseId
            ORDER BY CreatedDate DESC
        ];
            Map<String, List<ExternalFileWrapper>> docTypeExternalFileMap = new Map<String, List<ExternalFileWrapper>>();
            if (!extFiles.isEmpty()) {
                for (External_Files__c ext : extFiles) {
                    if (!docTypeExternalFileMap.containsKey(ext.Document__r.DocumentType__c)) {
                        docTypeExternalFileMap.put(ext.Document__r.DocumentType__c, new List<ExternalFileWrapper>());
                        system.debug('ext.Document__r.DocumentType__c getDocument'+ext.Document__r.DocumentType__c);
                    }
                    ExternalFileWrapper dw = new ExternalFileWrapper();
                    dw.documentType = ext.Document__r.DocumentType__c;
                    dw.fileName = ext.File_Name__c;
                    dw.fileLink = ext.External_URL__c;
                    dw.caseCommentSFId = ext.RETL_Case_Comment_SF_ID__c != null ? ext.RETL_Case_Comment_SF_ID__c : null;
                    system.debug('fileLink'+dw.fileLink);
                    docTypeExternalFileMap.get(ext.Document__r.DocumentType__c).add(dw);
                }
            }
            return docTypeExternalFileMap;
        }




        @AuraEnabled(cacheable=false)
        public static Map<String, List<ExternalFileWrapper>> getCaseDocuments(String caseId, String category) {
            Map<String, List<ExternalFileWrapper>> docTypeDocDataMap = getDocuments(caseId);
            Map<String, List<ExternalFileWrapper>> returnMap = new Map<String, List<ExternalFileWrapper>>();
            if ((category == 'NOC') && docTypeDocDataMap.containsKey('NOC')) {
                returnMap.put('Issued Document', docTypeDocDataMap.get('NOC'));
            }
            if ((category == 'Work Permit') && docTypeDocDataMap.containsKey('Permit to Work')) {
                returnMap.put('Issued Document', docTypeDocDataMap.get('Permit to Work'));
            }
            // if (docTypeDocDataMap.containsKey('Attachment Document')) {
                //     returnMap.put('Attachments', docTypeDocDataMap.get('Attachment Document'));
            // }
            for (String docType : docTypeDocDataMap.keySet()) {
                if (docType != category) {
                    returnMap.put(docType, docTypeDocDataMap.get(docType));
                }
            }
            return returnMap;
        }






        @AuraEnabled(cacheable=false)
        public static List<Map<String, Object>> getCaseCommentHistory(String caseId) {
            Map<String, List<ExternalFileWrapper>> docTypeDocDataMap = getDocuments(caseId);
            List<ExternalFileWrapper> caseCommentAttachedFiles = docTypeDocDataMap.ContainsKey('Case Comment') ? docTypeDocDataMap.get('Case Comment') : new List<ExternalFileWrapper>();
            return getCaseComment(caseId, null, caseCommentAttachedFiles);
        }

        @AuraEnabled(cacheable=false)
        // public static Map<String, Object> getCaseComment(String caseId, Map<String, Object> sectionFieldMap, List<ExternalFileWrapper> commentFiles) {
            public static List<Map<String, Object>> getCaseComment(String caseId, Map<String, Object> sectionFieldMap, List<ExternalFileWrapper> commentFiles) {
                if (String.isNotBlank(caseId)) {
                    List<CaseComment> casecmt = [
                SELECT Id, ParentId, CommentBody, IsPublished, CreatedBy.Name, CreatedDate, CreatedBy.Profile.Name, CreatedBy.Profile.UserType
                FROM CaseComment
                WHERE ParentId = :caseId AND IsPublished = true
                ORDER BY CreatedDate DESC
            ];

                    if(sectionFieldMap == null){
                        sectionFieldMap = new Map<String, Object>();
                    }
                    if (!sectionFieldMap.containsKey('Communication History')) {
                        sectionFieldMap.put('Communication History', new List<Map<String,Object>>());
                    }

                    List<Map<String,Object>> historyList = (List<Map<String,Object>>) sectionFieldMap.get('Communication History');

                    // Build a map of CaseCommentId -> ExternalFileWrapper list
                    Map<String,List<ExternalFileWrapper>> caseCommentIdExternalFileWrapperMap = new Map<String,List<ExternalFileWrapper>>();
                    if (!commentFiles.isEmpty()) {
                        for (ExternalFileWrapper file : commentFiles) {
                            if (file.caseCommentSFId != null) {
                                if (!caseCommentIdExternalFileWrapperMap.containsKey(file.caseCommentSFId)) {
                                    caseCommentIdExternalFileWrapperMap.put(file.caseCommentSFId, new List<ExternalFileWrapper>());
                                }
                                caseCommentIdExternalFileWrapperMap.get(file.caseCommentSFId).add(file);
                            }
                        }
                    }
                    system.debug('caseCommentIdExternalFileWrapperMap'+caseCommentIdExternalFileWrapperMap);
                    if (!casecmt.isEmpty()) {
                        for (CaseComment cc : casecmt) {
                            // create entry map for this comment
                            Map<String,Object> historyEntry = new Map<String,Object>();
                            historyEntry.put('caseCommentId', cc.Id);
                            historyEntry.put('comment', cc.CommentBody);
                            historyEntry.put('createdDate', String.valueOf(cc.CreatedDate));
                            historyEntry.put('createdBy', cc.CreatedBy.Profile.UserType == 'Standard' ? 'Aldar Retail' : cc.CreatedBy.Name);
                            historyEntry.put('createdByDirection', cc.CreatedBy.Profile.UserType == 'Standard' ? 'left' : 'right');

                            // always include DocLinks, even if empty
                            List<Map<String,Object>> docList = new List<Map<String,Object>>();

                            if (caseCommentIdExternalFileWrapperMap.containsKey(cc.Id)) {
                                for (ExternalFileWrapper file : caseCommentIdExternalFileWrapperMap.get(cc.Id)) {
                                    Map<String,Object> doc = new Map<String,Object>();
                                    doc.put('fileLink', file.fileLink);
                                    doc.put('fileName', file.fileName);
                                    docList.add(doc);
                                }
                            }

                            historyEntry.put('DocLinks', docList);
                            system.debug('historyEntry'+historyEntry);
                            historyList.add(historyEntry);
                        }
                    }
                    return historyList;
                }
                return null;
                // return sectionFieldMap;
            }


            @AuraEnabled
            public static Map<String, Object> saveCaseComment(Id caseId, String comment) {
                // System.debug('filesWrapper => ' + filesWrapper);
                //System.debug('filesWrapperJson => ' + filesWrapperJson);

                //DocumentWrapper filesWrapper = (DocumentWrapper) JSON.deserialize(filesWrapperJson, DocumentWrapper.class);
                //System.debug('filesWrapper after deserialization => ' + filesWrapper);
                List<External_Files__c> fileLinks = new List<External_Files__c>();
                if (String.isNotBlank(comment)) {
                    CaseComment cmt = new CaseComment(
                        ParentId = caseId,
                    CommentBody = comment,
                    IsPublished = true
                        );
                    insert cmt;
                    /* if (filesWrapper != null && filesWrapper.contentVersions != null && !filesWrapper.contentVersions.isEmpty() && cmt.Id != null) {
                        // handleDocuments already expects List<DocumentWrapper>
                        //fileLinks = handleDocuments(filesWrapperJson, cmt.Id);
                        System.debug('fileLinks in casecomment='+fileLinks);
                    }*/
                }

                List<CaseComment> caseComment = [
            SELECT Id, ParentId, CommentBody, CreatedDate, CreatedBy.Name
            FROM CaseComment
            WHERE ParentId = :caseId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
                if (caseComment.isEmpty()) {
                    return new Map<String, Object>();
                }

                Map<String, Object> justCreatedCaseComment =
                    (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(caseComment[0]));

                /*if (!fileLinks.isEmpty()) {
                    List<Map<String, Object>> docList = new List<Map<String, Object>>();
                    for (External_Files__c file : fileLinks) {
                        Map<String, Object> doc = new Map<String, Object>();
                        doc.put('fileLink', file.External_URL__c);
                        doc.put('fileName',file.File_Name__c);
                        docList.add(doc);
                    }
                    justCreatedCaseComment.put('DocLinks', docList);
                }
                System.debug('justCreatedCaseComment='+justCreatedCaseComment);*/
                    return justCreatedCaseComment;
            }

            public class ExternalFileWrapper {
                @AuraEnabled public String documentType;
                @AuraEnabled public String fileName;
                @AuraEnabled public String fileLink;
                @AuraEnabled public String caseCommentSFId;
            }



        }