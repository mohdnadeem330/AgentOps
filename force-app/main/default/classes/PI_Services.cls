public without sharing class PI_Services {
    
    Public Static String PILEAD_DOC_CATAGORY = 'PILead'; 
    Public Static String PIOPPORTUNITYSTAGE = 'Opportunity validation';
    Public Static String APPROVALSTATUSDEFAULT = 'None';
    Public Static String DOCUMENTG1 = 'PIOpportunityG1'; 
    Public Static String DOCUMENTG2 = 'PIOpportunityG2'; 
    Public Static String DOCUMENTG3 = 'PIOpportunityG3'; 
    Public Static String DOCUMENTG4 = 'PIOpportunityG4'; 
    Public Static String OPPActionReviewStatus = 'Action required'; 
    public static Id p_IRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('P_I_Lead').getRecordTypeId();
	public static Id oppPIRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('P_and_I_Opportunity').getRecordTypeId();
    public static Id accPIRecId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PI_Account').getRecordTypeId();
    public static Id ContactRecId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
     /**
     * @description createDocumentForPandILead description ASF-936
     * @param  leadList leadList description
     */ 
    public static void createDocumentForPandILead(List<Lead> newLeads){
        
        List<Document__c> documentListToInsert = new List<Document__c>();

        Map<String, Id> documentRecordTypeMap = new Map<String,Id>();

        Map<Id, Lead> oppIdToRecMap = new  Map<Id, Lead>(newLeads);

        Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{PILEAD_DOC_CATAGORY});
        System.debug('#### documentMap: '+documentMap);
        if(!documentMap.isEmpty()){
            //get Existing Documents
            Map<String, Document__c> existingDocMap = new Map<String, Document__c>();
            for(Document__c tempDoc : [SELECT Id, DocumentType__c, Lead__c 
                                        FROM Document__c 
                                        WHERE Lead__c IN :oppIdToRecMap.keySet()]){
                existingDocMap.put(tempDoc.Lead__c+tempDoc.DocumentType__c, tempDoc);
            }

            for(Lead leadRec : newLeads){
                //String documentTypeToProcess = 'P and I Lead'; 
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(PILEAD_DOC_CATAGORY)){
                    String recordTypeID = null;
                    if(tempMetaRec.RecordTypeDeveloperName__c != null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    //existing check
                    if(!existingDocMap.containsKey(leadRec.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                Lead__c = leadRec.Id,
                                                OwnerId = leadRec.OwnerId,
                                                RecordtypeId = recordTypeID,
                                                AvailableForExternalUsers__c = tempMetaRec.AvailableForExternalUsers__c,
                                                GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true) );
                        documentListToInsert.add(documentRecord); 
                        existingDocMap.put(leadRec.Id + tempMetaRec.DocumentType__c, documentRecord); 
                    }
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
    }
    /**
     * @description convertPandILeads description
     * @param  newLeads newLeads description
     */ 
    public static void convertPandILeads(List<Lead> leads){
        list<Database.LeadConvert> leadTobeConverted = new list<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        Map<Id,Lead> leadMap = new Map<Id,Lead>();
         System.debug('leadIds@@@@@'+leads);
        for(Lead lead : leads){ {
            leadMap.put(lead.Id, lead);
        }
        System.debug('leadMap+++++'+leadMap);
        Map<String, Document__c> documents = new Map<String, Document__c>();
        for(Document__c tempDoc : [SELECT Id, DocumentType__c, Opportunity__c ,lead__c
                                        FROM Document__c 
                                        WHERE lead__c IN : leadMap.keySet()]){

            documents.put(tempDoc.lead__c,tempDoc);
        }
        for(Lead tempLead : leads){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(tempLead.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            
            leadTobeConverted.add(lc);
        }
        List<Database.LeadConvertResult> lcr = Database.convertLead(leadTobeConverted);
        
        List<Document__c> docsToUpdate = new List<Document__c>();
        List<Contact> conList = new List<Contact>();
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        
        for (Database.LeadConvertResult lc: lcr) {
            system.debug(' lc----  '+lc );
            system.debug('lc.getLeadId()---- '+lc.getLeadId()); 
            Lead leadRec = leadMap.get(lc.getLeadId());
            system.debug('leadRec-------'+leadRec);
           
            Document__c doc = new Document__c();
            doc = documents.get(lc.getLeadId());
            
            Contact con = new Contact();
            con.Id = lc.getContactId();
            con.Email = leadRec.Email;
            con.EmailAddress__c = leadRec.Email;
            con.recordTypeId = ContactRecId;
            conList.add(con);

            Account acc = new Account();
            acc.Id = lc.getAccountId();
            acc.recordTypeId = accPIRecId;
            acc.Name = leadRec.Company;
            acc.Email__c = leadRec.Email;
            acc.EmailAddress__c = leadRec.Email;
            accList.add(acc);

            if(lc.getOpportunityId() != null ){
                doc.Opportunity__c = lc.getOpportunityId();
                docsToUpdate.add(doc);

                Opportunity oppRec = new Opportunity();
                oppRec.Id = lc.getOpportunityId();
                oppRec.recordTypeId = oppPIRecId;
                oppRec.Project_Country__c = leadRec.Project_Country__c;
                oppRec.Project_city__c = leadRec.Project_city__c;
                oppRec.Type__c = leadRec.Type__c;
                oppRec.Estimated_Deal_size__c = leadRec.Estimated_Deal_size__c;
                oppRec.PuP_Budget__c = leadRec.PuP_Budget__c;
                oppRec.PuP_Project_Code__c = leadRec.PuP_Project_Code__c;
                oppRec.Start_date__c = (leadRec.Start_date__c != null) ? leadRec.Start_date__c : null ;
                oppRec.Expected_due_date__c = (leadRec.Expected_due_date__c != null) ? leadRec.Expected_due_date__c : null ;
                oppRec.Ownership__c = leadRec.Ownership__c;
                oppRec.Deal_Type__C = leadRec.Deal_Type__C;
                oppRec.Commentary__c = leadRec.Commentary__c;
                oppRec.StageName = PIOPPORTUNITYSTAGE;
                oppRec.OwnerId = leadRec.OwnerId;
                oppRec.Approval_Status__c = APPROVALSTATUSDEFAULT;
                oppRec.Name = leadRec.Company;
                oppList.add(oppRec);
            }
        }
        
        if (!accList.isEmpty()) {
            TriggerHandler.processedIds = new Set<Id>();
            Update accList;
        }

        if(!oppList.isEmpty()){
            Update oppList;
            createDocumentForOpportunity(oppList);
        }

        if(!conList.isEmpty()){
            Update conList;
        }
        if(!docsToUpdate.isEmpty()){
            Update docsToUpdate;
        }
    }
    }
    /**
     * @description createDocumentForOpportunity description ASF-936
     * @param  newOpportunities newOpportunities description
     */ 
    public static void createDocumentForOpportunity(List<Opportunity> newOpportunities){
        
        List<Document__c> documentListToInsert = new List<Document__c>();

        Map<String, Id> documentRecordTypeMap = new Map<String,Id>();

        Map<Id, Opportunity> oppIdToRecMap = new  Map<Id, Opportunity>(newOpportunities);

        Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{DOCUMENTG1});
        documentMap.putAll(DocumentService.getDocumentMetaDataByCategory(new Set<String>{DOCUMENTG2}));
        documentMap.putAll(DocumentService.getDocumentMetaDataByCategory(new Set<String>{DOCUMENTG3}));
        documentMap.putAll(DocumentService.getDocumentMetaDataByCategory(new Set<String>{DOCUMENTG4}));
        
        System.debug('#### documentMap: '+documentMap);
        if(!documentMap.isEmpty()){
            //get Existing Documents
            Map<String, Document__c> existingDocMap = new Map<String, Document__c>();
            for(Document__c tempDoc : [SELECT Id, DocumentType__c, Opportunity__c 
                                        FROM Document__c 
                                        WHERE Opportunity__c IN :oppIdToRecMap.keySet()]){
                existingDocMap.put(tempDoc.Opportunity__c+tempDoc.DocumentType__c, tempDoc);
            }

            for(Opportunity oppRec : newOpportunities){
                String documentTypeToProcess = DOCUMENTG1; 
                if (oppRec.Approval_Status__c == 'Validation approved') {
                    documentTypeToProcess = DOCUMENTG2; 
                }else if (oppRec.Approval_Status__c == 'Execution approved') {
                    documentTypeToProcess = DOCUMENTG3; 
                }else if (oppRec.Approval_Status__c == 'Investment Monitoring approved') {
                    documentTypeToProcess = DOCUMENTG4; 
                }
                system.debug('documentTypeToProcess>>>'+documentTypeToProcess);
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                    String recordTypeID = null;
                    if(tempMetaRec.RecordTypeDeveloperName__c != null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    //existing check
                    if(!existingDocMap.containsKey(oppRec.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                Opportunity__c = oppRec.Id,
                                                OwnerId = oppRec.OwnerId,
                                                RecordtypeId = recordTypeID,
                                                AvailableForExternalUsers__c = tempMetaRec.AvailableForExternalUsers__c,
                                                GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true) );
                        documentListToInsert.add(documentRecord); 
                        existingDocMap.put(oppRec.Id + tempMetaRec.DocumentType__c, documentRecord); 
                    }
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
    }
}