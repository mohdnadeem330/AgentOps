public class RETL_ProposalAPIService {

    public static String buildProposalJSON(Id proposalId) {

        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> data = new Map<String, Object>();

        if (proposalId == null) {
            response.put('status', 'Success');
            response.put('message', 'Proposal Id is required');
            response.put('data', new Map<String, Object>());
            return JSON.serializePretty(response);
        }

        try {
            // --- CONSOLIDATED SOQL QUERIES ---
            List<Opportunity> opportunities = getOpportunityDetail(proposalId);
            Opportunity opp = opportunities.isEmpty() ? null : opportunities[0];

            if (opp == null) {
                response.put('status', 'Error');
                response.put('message', 'No Opportunity record found');
                response.put('data', new Map<String, Object>());
                return JSON.serializePretty(response);
            }

            List<RETL_Stage__c> stages = getStages(proposalId);

            Map<Id, String> tenantNameByStageId = new Map<Id, String>();
            for(RETL_Stage__c s : stages) {
                if (s.RETL_Service_RequestId__r.RETL_Tenant__r.Name != null) {
                    tenantNameByStageId.put(s.Id, s.RETL_Service_RequestId__r.RETL_Tenant__r.Name);
                }
            }
            List<RETL_Service_Request__c> serviceRequests = getServiceRequest(proposalId);
            
            Set<Id> stageIds = new Set<Id>();
            for(RETL_Stage__c s : stages) {
                stageIds.add(s.Id);
            }

            String serviceRequestId = serviceRequests.isEmpty() ? null : serviceRequests[0].Id;
            String sfOrderId = serviceRequests.isEmpty() ? null : serviceRequests[0].RETL_Order__c;

            // Bulk query for External_Files related to service request/documents for design phase
            Map<Id, String> externalFilesMapByDocId = new Map<Id, String>();
            if (serviceRequestId != null) {
                for (External_Files__c ef : getExternalFilesByServiceReqId(serviceRequestId)) {
                    if (ef.Document__c != null) {
                        externalFilesMapByDocId.put(ef.Document__c, ef.External_URL__c);
                    }
                }
            }

            // Bulk query for documents related to Unit_Handover stage
            Map<Id, Document__c> handoverDocsByStageId = new Map<Id, Document__c>();
            for (Document__c doc : getHandoverDocuments(stageIds)) {
                handoverDocsByStageId.put(doc.RETL_Stage__c, doc);
            }

            // Bulk query for 'Approval to Trade' documents
            Map<Id, Document__c> approvalToTradeDocsByStageId = new Map<Id, Document__c>();
            for (Document__c doc : getApprovalToTradeDocuments(stageIds)) {
                approvalToTradeDocsByStageId.put(doc.RETL_Stage__c, doc);
            }

            // Bulk query for Events related to Kick_Off stages
            Map<Id, List<Event>> kickOffEventsByStageId = getKickOffEvents(stageIds);
            
            // Bulk query for Construction Update Images
            List<Document__c> constructionImages = getConstructionUpdateImages(opp.Id);
            
            // Bulk query for Review History (ContentNotes and related External_Files)
            Map<Id, Map<String, Object>> reviewHistoryMapByStageId = buildReviewHistoryBulk(stageIds, tenantNameByStageId, opp);

            Map<Id, String> oppExternalFilesByOppId = getOppExternalFilesByOppId(proposalId);

            // --- BUILD JSON DATA ---
            data.put('proposalId', getValue(proposalId));

            String title = (opp.RETL_Brand__r?.Name != null ? opp.RETL_Brand__r.Name : '');
            if(String.isNotBlank(title) && opp.RETL_Project__r?.Name != null) {
                title += ', '; 
            }
            title += opp.RETL_Project__r?.Name != null ? opp.RETL_Project__r.Name : '';
            data.put('title', title);

            data.put('propertyName', getValue(opp.RETL_Project__r?.Name));
            data.put('propertyCode', getValue(opp.RETL_Project__r?.RETL_Property_Yardi_Code__c));
            data.put('currentPhase', getValue(opp.RETL_Live_Aldar_Phase__c));
            data.put('serviceRequestId', serviceRequests.isEmpty() ? '' : getValue(serviceRequests[0].Id));
            data.put('sfOrderId ', getValue(sfOrderId));
            data.put('yardiId', getValue(opp.RETL_Yardi_Id__c));
            data.put('yardiProposalId', getValue(opp.RETL_Yardi_Proposal_Id__c));
            data.put('yardiTenantCode', getValue(opp.RETL_Tenant_Code__c));
            // data.put('salesCategory', getValue(opp.RETL_Sales_Category__c));
            // data.put('totalPhases', new List<String>{'Leasing','Design','Fit-Out','In-Life'});
            data.put('totalPhases', getRecordTypeStages('Opportunity', 'RETL_Opportunity','RETL_Live_Aldar_Phase__c'));
            
            // Pass pre-queried data to phase building methods
            data.put('Leasing', buildLeasingPhase(opp, serviceRequests, oppExternalFilesByOppId));
            data.put('Design', buildDesignPhase(stages, externalFilesMapByDocId, kickOffEventsByStageId, handoverDocsByStageId, approvalToTradeDocsByStageId, reviewHistoryMapByStageId));
            data.put('Fit-Out', buildConstructionPhase(stages, constructionImages, kickOffEventsByStageId, handoverDocsByStageId, approvalToTradeDocsByStageId, reviewHistoryMapByStageId));
            data.put('In-Life', buildInLifePhase());  
			
            response.put('status', 'Success');
            response.put('message', 'Request processed successfully');
            response.put('data', data); 
        }
        catch (Exception ex) {
            System.debug('Error in buildProposalJSON: ' + ex.getMessage() + '\n' + ex.getStackTraceString());
            response.put('status', 'Error');
            response.put('message', ex.getMessage());
            response.put('data', new Map<String, Object>());
        }

        return JSON.serializePretty(response);
    }
    
    // --- UTILITY METHODS (Refactored or Simplified) ---
    @testVisible
    private static Object getValue(Object value) {
        return value == null ? '' : value;
    }

    // New bulkified SOQL methods

    private static List<External_Files__c> getExternalFilesByServiceReqId(String serviceRequestId){
        return [
            SELECT Id, Document__c, External_URL__c
            FROM External_Files__c 
            WHERE Document__r.RETL_Stage__r.RETL_Service_RequestId__c = :serviceRequestId
        ];
    }
    
    private static List<Document__c> getHandoverDocuments(Set<Id> stageIds) {
        if(stageIds.isEmpty()) return new List<Document__c>();
        return [
            SELECT Id, RETL_Stage__c
            FROM Document__c
            WHERE RETL_Stage__c IN :stageIds
            AND DocumentType__c = 'Handover Certificate' AND Status__c = 'Signed'
        ];
    }

    private static List<Document__c> getApprovalToTradeDocuments(Set<Id> stageIds) {
        if(stageIds.isEmpty()) return new List<Document__c>();
        return [
            SELECT Id, RETL_Stage__c
            FROM Document__c
            WHERE RETL_Stage__c IN :stageIds
            AND DocumentType__c = 'Approval to Trade'
        ];
    }

    private static Map<Id, List<Event>> getKickOffEvents(Set<Id> stageIds) {
        Map<Id, List<Event>> eventsByStageId = new Map<Id, List<Event>>();
        if (stageIds.isEmpty()) return eventsByStageId;

        for (Event e : [
            SELECT Id, Location, StartDateTime, EndDateTime, RETL_Status__c, WhatId
            FROM Event
            WHERE WhatId IN :stageIds AND RETL_Status__c != 'Rejected' ORDER BY CreatedDate DESC
        ]) {
            if (e.WhatId != null) {
                if (!eventsByStageId.containsKey(e.WhatId)) {
                    eventsByStageId.put(e.WhatId, new List<Event>());
                }
                eventsByStageId.get(e.WhatId).add(e);
            }
        }
        return eventsByStageId;
    }

    private static List<Document__c> getConstructionUpdateImages(Id oppId) {
        return [
            SELECT Id, CreatedDate, DocumentType__c, RETL_Attachment_URL__c
            FROM Document__c
            WHERE DocumentType__c = 'Fit Out Updates'
            AND Opportunity__r.Id = :oppId
            ORDER BY CreatedDate ASC
        ];
    }


    private static Map<String, Object> buildStageMap(
        RETL_Stage__c stage, 
        Map<Id, String> externalFilesMap, 
        Map<Id, List<Event>> kickOffEvents, 
        Map<Id, Document__c> handoverDocs, 
        Map<Id, Document__c> approvalToTradeDocs,
        Map<Id, Map<String, Object>> reviewHistoryMap
    ) {
        
        Map<String, Object> stageMap = new Map<String, Object>{
            'stageId'             => getValue(stage.Id),
            'sequence'            => getValue(stage.Sequence__c),
            'name'                => getValue(stage.Name),
            'status'              => getValue(stage.Status__c),
            'serviceRequestId'    => getValue(stage.RETL_Service_RequestId__c),
            'stageDeveloperName'  => getValue(stage.StageTemplateId__r.RETL_Stage_Developer_Name__c),
            'documentReviewStatus'  => getValue(stage.RETL_Document_Review_Status__c),
            'uploadedDocuments'   => new Map<String, Object>{
                'listOfDocuments' => buildDocumentList(stage.Documents__r, externalFilesMap)
            },
            'reviewHistory'       => reviewHistoryMap.get(stage.Id) != null 
                                     ? reviewHistoryMap.get(stage.Id).get('reviewHistory')
                                     : new List<Object>()
        };

        String devName = stage.StageTemplateId__r.RETL_Stage_Developer_Name__c;

        if (devName == 'Kick_Off') {
            stageMap.put('kickOffMeeting', buildKickOffMeeting(stage.Id, stage.Name, kickOffEvents));
        }

        if (devName == 'Unit_Handover') {
            stageMap.putAll(buildHandoverDetails(stage.Id, handoverDocs));
            stageMap.put('siteInspectionPending', siteInspectionPending(stage));
        }
        
        if (devName == 'Fit_Out_and_Trade_Approval') {
             stageMap.put('approvalToTrade', approvalToTrade(stage.Id, approvalToTradeDocs));
             stageMap.put('siteInspectionPending', siteInspectionPending(stage));
        }


        return stageMap;
    }

    
    private static Map<String, Object> buildLeasingPhase(Opportunity opp, List<RETL_Service_Request__c> serviceRequests, Map<Id, String> oppExternalFilesByOppId) {
        String unitNumber = String.valueOf(getValue(opp.UnitNumber__c));
        if((!serviceRequests.isEmpty())){
            if(serviceRequests[0].RETL_Order__r?.Unit_Number__c != NULL){
                unitNumber = serviceRequests[0].RETL_Order__r.Unit_Number__c ;
            }
        }
        Map<String, Object> leasing = new Map<String, Object>{
             'dateOfOfferAcceptance'     => getValue(opp.OfferAcceptedDate__c),
             //'dateOfCommitteeApproval'   => (!serviceRequests.isEmpty()) ? serviceRequests[0].RETL_Order__r.RETL_Date_of_Committee_Approval__c : null,
             'dateOfCommitteeApproval'   => getValue(opp.RETL_Committee_Approval_Date__c),
             'dateOfSigningLeaseAgreement'   => getValue(opp.RETL_Lease_Agreement_Signed_Date__c),
             //'dateOfSigningLeaseAgreement' => (!serviceRequests.isEmpty()) ? serviceRequests[0].RETL_Order__r.RETL_Date_Of_Signing_Lease_Agreement__c : null,
             //'Tips'                      => (!serviceRequests.isEmpty()) ? serviceRequests[0].RETL_Order__r.RETL_Leasing_Tips__c : '',
             'currentStage'              => getValue(opp.RETL_Leasing_Phase_Stage__c),
             //'unitNumber'                => (!serviceRequests.isEmpty()) ? serviceRequests[0].RETL_Order__r.Unit_Number__c : getValue(opp.UnitNumber__c),
             'unitNumber'                => unitNumber,
             'stages'                    => getValue(getRecordTypeStages('Opportunity', 'RETL_Opportunity','RETL_Leasing_Phase_Stage__c')),
             'location'                  => getValue(opp.RETL_Location__c),
             'offerDate'                 => getValue(opp.RETL_Offer_Date__c),
             'offerValidity'             => getValue(opp.RETL_Offer_Validity__c),
             'footfall'                  => getValue(opp.RETL_Footfall__c),
             'nearbyStoreSales'          => getValue(opp.RETL_Nearby_Store_Sales__c),
             'constructionCost'          => getValue(opp.RETL_Construction_Cost__c),
             'uploadedDocuments'   => new Map<String, Object>{
                'listOfDocuments' => buildDocumentList(opp.Documents__r, oppExternalFilesByOppId)
             }
        };
        
        List<External_Files__c> externalFiles = getExternalFilesByOppId(opp.Id); 
        leasing.put('offerDocumentDownloadURL', (!externalFiles.isEmpty()) ? externalFiles[0].External_URL__c : '');

        List<External_Files__c> orderExternalFiles = getOrderExternalFilesByOppId(opp.Id); 
        leasing.put('leaseAgreementDownloadURL', (!orderExternalFiles.isEmpty()) ? orderExternalFiles[0].External_URL__c : '');

        leasing.put('contactPerson', buildContactPerson(opp.Owner));

        //leasing.put('distanceToFacilities', buildDistanceToFacilities(opp));
        
        leasing.put('totalBaseRent', getValue(opp.RETL_Total_Base_Rent__c));
        leasing.put('totalServiceCharge', getValue(opp.RETL_Total_Service_Charge__c));
        leasing.put('totalMarketingAmount', getValue(opp.RETL_Total_Marketing_Amount__c));
        leasing.put('totalFitoutAmount', getValue(opp.RETL_Total_FOC_Amount__c));
        leasing.put('turnOverRentPercent',  getValue(opp.RETL_TOR__c));
        leasing.put('salesCategory',  getValue(opp.RETL_Sales_Category__c));
        // data.put('salesCategory', getValue(opp.RETL_Sales_Category__c));

        return leasing;
    }
	
    private static Map<String, Object> buildDesignPhase(
        List<RETL_Stage__c> stages, 
        Map<Id, String> externalFilesMap, 
        Map<Id, List<Event>> kickOffEvents, 
        Map<Id, Document__c> handoverDocs, 
        Map<Id, Document__c> approvalToTradeDocs,
        Map<Id, Map<String, Object>> reviewHistoryMap
    ) {
        Map<String, Object> design = new Map<String, Object>();
        List<Object> designStages = new List<Object>();
        
        if (!stages.isEmpty()) {
            for (RETL_Stage__c s : stages) {
                if (s.RETL_Category__c == 'Design') {
                    designStages.add(buildStageMap(s, externalFilesMap, kickOffEvents, handoverDocs, approvalToTradeDocs, reviewHistoryMap));
                }
            }

            design.put('stages', designStages);

            String leasingManager = (
                stages[0].RETL_Service_RequestId__r.RETL_Leasing_Manager__r.Name != null
            ) ? stages[0].RETL_Service_RequestId__r.RETL_Leasing_Manager__r.Name : 'Leasing Manager';

            design.put('contactPerson', new Map<String, Object>{
                'name'        => getValue(leasingManager),
                'designation' => 'Leasing Manager',
                'phone'       => '1800-ALDAR'
            });
        }

        return design;
    }

    private static Map<String, Object> buildConstructionPhase(
        List<RETL_Stage__c> stages, 
        List<Document__c> constructionImages,
        Map<Id, List<Event>> kickOffEvents, 
        Map<Id, Document__c> handoverDocs, 
        Map<Id, Document__c> approvalToTradeDocs,
        Map<Id, Map<String, Object>> reviewHistoryMap
    ) {
        String rawDocs;
        List<String> docTypes;
        String cleanItem;
        String fitOutStageRecordId = '';
        DateTime lastUpdatedOn;
        DateTime anticipatedCompletionDate;
        Id oppId = stages.isEmpty() ? null : stages[0].RETL_Service_RequestId__r.RETL_Opportunity_Id__c;
        Map<String, Object> constructionPhaseMap = new Map<String, Object>();
        Decimal percentCompletion;

        if (!stages.isEmpty()) {
            List<Object> constructionStages = new List<Object>();
            Map<Id, String> externalFilesMap = new Map<Id, String>(); 

            for (RETL_Stage__c s : stages) {
                if (s.RETL_Category__c != 'Construction') continue;

                Map<String, Object> stg = buildStageMap(s, externalFilesMap, kickOffEvents, handoverDocs, approvalToTradeDocs, reviewHistoryMap);

                if (s.StageTemplateId__r.RETL_Stage_Developer_Name__c == 'Fit_Out_and_Trade_Approval') {
                    fitOutStageRecordId = s.Id;
                    anticipatedCompletionDate = s.RETL_Target_End_Date__c;
                    lastUpdatedOn = s.LastModifiedDate;
                    // ----------- 'percentCompletion' -----------
                    percentCompletion = s.RETL_Percent_Completion__c != null ? s.RETL_Percent_Completion__c : null;
                }

                if (s.StageTemplateId__r.RETL_Stage_Developer_Name__c == 'Pre_Start') { 
                    rawDocs = s.RETL_Missing_Documents_Details__c;
                    docTypes = new List<String>();
                    if (!String.isBlank(rawDocs)) {
                        for (String item : rawDocs.split(',')) {
                            cleanItem = item.trim();
                            if (String.isNotEmpty(cleanItem)) {
                                docTypes.add(cleanItem);
                            }
                        }
                    }
                    // ----------- 'missingDocuments' ------------
                    if(docTypes.size() > 0 || !docTypes.isEmpty()){
                        stg.put('missingDocuments', new Map<String, Object>{
                            'listOfDocuments'   => docTypes,
                            'uploadByDate'      => s.RETL_Missing_Document_Due_Date__c
                        });
                    } else {
                        stg.put('missingDocuments', new Map<String, Object>());
                    }
                } 
                
                constructionStages.add(stg);
            }

            List<Object> updates = new List<Object>();
            for (Document__c d : constructionImages) {
                updates.add(new Map<String, Object>{
                    'date'     => getValue(String.valueOf(d.CreatedDate)),
                    'imageURL' => getValue(d.RETL_Attachment_URL__c)
                });
            } 
        
            Map<String, Object> constructionDetails = new Map<String, Object>();
            constructionDetails.put('anticipatedCompletionDate', anticipatedCompletionDate);
            constructionDetails.put('percentCompletion', percentCompletion);
            constructionDetails.put('lastUpdatedOn', lastUpdatedOn);

            List<Case> cases = getCase(fitOutStageRecordId); 

            constructionPhaseMap = new Map<String, Object>{
                'stages'               => constructionStages,
                'constructionUpdates'  => updates,
                'constructionDetails'  => constructionDetails,
                'serviceRequestNumber' => cases.isEmpty() ? '' : cases[0].CaseNumber,
                'serviceRequestStatus' => cases.isEmpty() ? '' : cases[0].Status
            };
        }
        return constructionPhaseMap;
    }
    
    private static List<Object> buildKickOffMeeting(Id stageId, String stageName, Map<Id, List<Event>> kickOffEvents) {
        if (!kickOffEvents.containsKey(stageId) || stageName != 'Kick-Off') return new List<Object>();

        List<Event> events = kickOffEvents.get(stageId);
        if (events.isEmpty()) return null;

        Event e = events[0];

        return new List<Object>{
            new Map<String, Object>{
                'location' => getValue(e.Location),
                'date'     => getValue(e.StartDateTime),
                'timeSlot' => getValue(e.StartDateTime.format('hh:mm a') + ' - ' + e.EndDateTime.format('hh:mm a')),
                'status'   => getValue(e.RETL_Status__c),
                'eventId'  => getValue(e.Id)
            }
        };
    }

    private static Map<String, Object> buildHandoverDetails(Id stageId, Map<Id, Document__c> handoverDocs) {
        String status = handoverDocs.containsKey(stageId) ? 'signed' : 'pending';
        return new Map<String, Object>{
            'handOverCertificate'   => new Map<String, String>{ 'status' => status }
        };
    }

    private static Boolean approvalToTrade(Id stageId, Map<Id, Document__c> approvalToTradeDocs) {
        return approvalToTradeDocs.containsKey(stageId);
    }
    
    private static Map<Id, Map<String, Object>> buildReviewHistoryBulk(Set<Id> stageIds, Map<Id, String> tenantNameByStageId, Opportunity opp) {
        Map<Id, Map<String, Object>> historyMapByStageId = new Map<Id, Map<String, Object>>();
        if (stageIds.isEmpty()) return historyMapByStageId;
        
        // 1. Get all ContentDocumentLinks for all stages
        List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :stageIds];
        
        Set<Id> contentDocIds = new Set<Id>();
        Map<Id, Id> docIdToStageId = new Map<Id, Id>(); 
        for(ContentDocumentLink link : links) {
            contentDocIds.add(link.ContentDocumentId);
            docIdToStageId.put(link.ContentDocumentId, link.LinkedEntityId);
        }

        if (contentDocIds.isEmpty()) return historyMapByStageId;

        // 2. Get all ContentNotes and External_Files related to those Ids
        List<ContentNote> contentNotes = [
            SELECT Id, Title, TextPreview, CreatedDate, Createdby.Name, Owner.Name 
            FROM ContentNote 
            WHERE Id IN :contentDocIds 
            ORDER BY CreatedDate
        ];
        
        // Use a single query for all External_Files
        List<External_Files__c> externalFiles = [
            SELECT Id, RETL_Case_Comment_SF_ID__c, CreatedDate, External_URL__c, 
                   Document__r.RETL_Yardi_Id__c, Document__r.Name, Document__r.DocumentType__c, 
                   Document__r.CreatedDate, Document__r.Status__c, Document__r.RecordType.Name 
            FROM External_Files__c 
            WHERE RETL_Case_Comment_SF_ID__c IN :contentDocIds
        ];

        // 3. Map External Files to ContentNote IDs
        Map<Id, List<Map<String, Object>>> filesByContentNoteId = new Map<Id, List<Map<String, Object>>>();
        for (External_Files__c externalFileObj : externalFiles) {
            Id contentNoteId = externalFileObj.RETL_Case_Comment_SF_ID__c;
            if (!filesByContentNoteId.containsKey(contentNoteId)) {
                filesByContentNoteId.put(contentNoteId, new List<Map<String, Object>>());
            }
            
            filesByContentNoteId.get(contentNoteId).add(new Map<String, Object>{
                'documentURL'     => externalFileObj.External_URL__c,
                'recordType'      => externalFileObj.Document__r?.RecordType?.Name,
                'status'          => externalFileObj.Document__r?.Status__c,
                'uploadedDate'    => externalFileObj.Document__r?.CreatedDate?.format(),
                'type'            => externalFileObj.Document__r?.DocumentType__c,
                'documentName'    => externalFileObj.Document__r?.Name,
                'documentIdYardi' => externalFileObj.Document__r?.RETL_Yardi_Id__c
            });
        }

        // 4. Build the final review history list, grouped by StageId
        for (ContentNote cn : contentNotes) {
            Id stageId = docIdToStageId.get(cn.Id);
            if (stageId == null) continue;

            if (!historyMapByStageId.containsKey(stageId)) {
                historyMapByStageId.put(stageId, new Map<String, Object>{'reviewHistory' => new List<Object>()});
            }

            String createdByName = cn.Createdby.Name;
            String tenantName = tenantNameByStageId.get(stageId);
            String ownerName = opp.Owner.Name; 

            Map<String, Object> docInfo = new Map<String, Object>{
                'id'              => cn.Id,
                'title'           => cn.Title,
                'text'            => cn.TextPreview,
                'timestamp'       => cn.CreatedDate,
                'listOfDocuments' => filesByContentNoteId.containsKey(cn.Id) 
                                     ? filesByContentNoteId.get(cn.Id) 
                                     : new List<Map<String, Object>>()
            };
            
            docInfo.put('owner', createdByName.contains('Integration User') ? tenantName : createdByName); 
            docInfo.put('commentedBy', createdByName.contains('Integration User') ? 'TENANT' : 'RDD MANAGER'); 

            ((List<Object>)historyMapByStageId.get(stageId).get('reviewHistory')).add(docInfo);
        }
        
        return historyMapByStageId;
    }
    
    
    private static List<Opportunity> getOpportunityDetail(Id proposalId) {
        return [
            SELECT Id, Name, StageName, RETL_Project__c, Unit__c, UnitNumber__c, AccountId,
                   Owner.Name, Owner.Title, Owner.Phone,
                   OfferAcceptedDate__c, RETL_Committee_Approval_Date__c,
                   RETL_Brand__r.Name, RETL_Project__r.Name, RETL_Project__r.RETL_Property_Yardi_Code__c,
                   RETL_Lease_Agreement_Signed_Date__c, RETL_Leasing_Tips__c,
                   RETL_Lease_Agreement_URL__c, 
                   RETL_DistanceToFacilities_Lift__c, RETL_DistanceToFacilities_Escalator__c, 
                   RETL_DistanceToFacilities_Information__c, RETL_DistanceToFacilities_Restroom__c, 
                   RETL_DistanceToFacilities_Dining__c, RETL_Location__c, RETL_Offer_Date__c, RETL_Offer_Validity__c, RETL_Footfall__c, 
                   RETL_Nearby_Store_Sales__c, RETL_Construction_Cost__c, RETL_Offer_Document_Download_URL__c, RETL_Classification__c, RETL_Leasing_Phase_Stage__c, RETL_Live_Aldar_Phase__c, 
                   RETL_Order__c, RETL_Yardi_Id__c, RETL_Sales_Category__c, RETL_Total_Base_Rent__c, RETL_Total_Service_Charge__c, RETL_Total_Marketing_Amount__c, 
            	   RETL_Total_FOC_Amount__c, RETL_TOR__c, RETL_Yardi_Proposal_Id__c, RETL_Tenant_Code__c,
                   (SELECT Id, Name, DocumentType__c, Status__c, CreatedDate, RecordType.Name, RETL_Yardi_Id__c FROM Documents__r)
            FROM Opportunity
            WHERE Id = :proposalId
            LIMIT 1
        ];
    }

    private static List<RETL_Stage__c> getStages(Id proposalId) {
        return [
            SELECT Id, Name, Sequence__c, Status__c, RETL_Site_Inspection__c,
                   RETL_Category__c, RETL_Missing_Documents__c,RETL_Missing_Documents_Details__c,
                   StageTemplateId__r.RETL_Stage_Developer_Name__c,
                   RETL_Service_RequestId__c,
                   RETL_Service_RequestId__r.RETL_Opportunity_Id__c,
                   RETL_Service_RequestId__r.RETL_Leasing_Manager__r.Name, RETL_Target_End_Date__c, LastModifiedDate, 
                   RETL_Site_Inspection_Status__c, RETL_Service_RequestId__r.RETL_Tenant__r.Name, RETL_Missing_Document_Due_Date__c, 
                   RETL_Document_Review_Status__c, RETL_Percent_Completion__c,
                   (SELECT Id, Name, DocumentType__c, Status__c, CreatedDate, RecordType.Name, RETL_Yardi_Id__c FROM Documents__r)
            FROM RETL_Stage__c
            WHERE RETL_Service_RequestId__r.RETL_Opportunity_Id__c = :proposalId
              AND Sequence__c != null
            ORDER BY Sequence__c ASC
        ];
    }
    
    
    private static List<RETL_Service_Request__c> getServiceRequest(Id proposalId) {
        return [
            SELECT Id, RETL_Opportunity_Id__c, 
            RETL_Order__r.RETL_Date_Of_Signing_Lease_Agreement__c, RETL_Order__r.RETL_Leasing_Tips__c, RETL_Order__r.RETL_Date_of_Committee_Approval__c,
            RETL_Order__r.Unit_Number__c, RETL_Order__c
            FROM RETL_Service_Request__c
            WHERE RETL_Opportunity_Id__c = :proposalId
        ];
    }
    
    private static List<External_Files__c> getExternalFilesByOppId(String oppId){
        return [
            SELECT Id, External_URL__c FROM External_Files__c WHERE Document__r.Opportunity__c = :oppId AND Document__r.DocumentType__c IN ('Signed Offer Letter','Offer Letter','Draft Offer Letter') /* AND Document__r.status__c = 'Signed' */ ORDER BY CreatedDate DESC LIMIT 1
        ];
    }

    private static List<External_Files__c> getOrderExternalFilesByOppId(String oppId){
        return [
            SELECT Id, External_URL__c, Document__r.Opportunity__c FROM External_Files__c WHERE Document__r.Opportunity__c = :oppId  AND Document__r.DocumentType__c IN ('Lease Agreement', 'Draft Lease Agreement') /*AND Document__r.status__c = 'Signed'*/  ORDER BY CreatedDate DESC LIMIT 1
        ];
    }

    private static Map<Id, String> getOppExternalFilesByOppId(String oppId) {
        Map<Id, String> oppIdToExternalUrl = new Map<Id, String>();

        List<External_Files__c> files = [
            SELECT Id, External_URL__c, Document__r.Opportunity__c
            FROM External_Files__c
            WHERE Document__r.Opportunity__c = :oppId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        for (External_Files__c file : files) {
            if (file.Document__r.Opportunity__c != null) {
                oppIdToExternalUrl.put(
                    file.Document__r.Opportunity__c,
                    file.External_URL__c
                );
            }
        }

        return oppIdToExternalUrl;
    }
    
    private static List<Map<String, Object>> buildContactPerson(User owner) { 
        List<Map<String, Object>> contactPersons = new List<Map<String, Object>>();
        contactPersons.add(new Map<String, Object>{
                'name'      => (owner != null && String.isNotBlank(owner.Name)) ? getValue(owner.Name) : '',
                'designation' => (owner != null && String.isNotBlank(owner.Title))? getValue(owner.Title) : '',
                'phone'       => '1800-ALDAR'
            });
        return contactPersons;
    }
    
    @testVisible
    private static Map<String, Object> buildInLifePhase() {
        return new Map<String, Object>();
    } 
    
    private static Map<String, Object> buildDistanceToFacilities(Opportunity opp){
        Map<String, Object> distanceToFacilities = new Map<String, Object>{
            'lift' => (opp?.RETL_DistanceToFacilities_Lift__c != null) ? opp.RETL_DistanceToFacilities_Lift__c : '',
            'escalator' => (opp?.RETL_DistanceToFacilities_Escalator__c != null) ? opp.RETL_DistanceToFacilities_Escalator__c : '',
            'information' => (opp?.RETL_DistanceToFacilities_Information__c != null) ? opp.RETL_DistanceToFacilities_Information__c : '',
            'restroom' => (opp?.RETL_DistanceToFacilities_Restroom__c != null) ? opp.RETL_DistanceToFacilities_Restroom__c : '',
            'classification' => (opp?.RETL_Classification__c != null) ? opp.RETL_Classification__c : '',
            'dining' => (opp?.RETL_DistanceToFacilities_Dining__c != null) ? opp.RETL_DistanceToFacilities_Dining__c : ''
        };
        return distanceToFacilities;
    }
    @testVisible
    private static List<Object> buildDocumentList(List<Document__c> docs, Map<Id, String> externalFilesMap) {
        List<Object> docList = new List<Object>();

        if (docs == null) return docList;

        for (Document__c d : docs) {
            docList.add(new Map<String, Object>{
                'documentIdYardi'   => getValue(d.RETL_Yardi_Id__c),
                'documentName'  => getValue(d.Name),
                'type'          => getValue(d.DocumentType__c),
                'uploadedDate'  => getValue(String.valueOf(d.CreatedDate)),
                'status'        => getValue(d.Status__c),
                'recordType'    => getValue(d.RecordType.Name),
                'documentURL'   => (externalFilesMap != null && externalFilesMap.containsKey(d.Id)) ? externalFilesMap.get(d.Id) : ''
            });
            
        }
        
        return docList;
    }
    @testVisible
    private static String siteInspectionPending(RETL_Stage__c stage){
        return stage.RETL_Site_Inspection_Status__c;// != 'Completed';
    }
    
    private static List<String> getRecordTypeStages(String objectName, String developerName,String fieldName) {
        Id recordTypeId = [
            SELECT Id FROM RecordType
            WHERE SObjectType = :objectName
              AND DeveloperName = :developerName
            LIMIT 1
        ].Id;

        Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.DescribeFieldResult fld = d.fields.getMap().get(fieldName).getDescribe();

        List<String> values = new List<String>();

        for (Schema.PicklistEntry e : fld.getPicklistValues()) {
            if (e.isActive()) values.add(e.getLabel());
        }

        return values;
    }

    private static List<Case> getCase(String fitOutStageRecordId) {
        if (fitOutStageRecordId == null) return new List<Case>();
        return [
            SELECT Id, RETL_Workflow_Stage__r.Name, CaseNumber, Status FROM Case WHERE RETL_Workflow_Stage__r.Id = :fitOutStageRecordId
        ];
    }
}