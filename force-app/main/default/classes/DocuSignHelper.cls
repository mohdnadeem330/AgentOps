/**-------------------------------------------------------------------
* Description : used to send docusign envelope
* -------------------------------------------------------------------
* History :
* [24.AUG.2023] tdontha@aldar.com - ASF-1403
* [18.JAN.2024] tdontha@aldar.com - BPE-87
* -------------------------------------------------------------------
*/
//This classe is executed from the Hexa BPM with full access
public without sharing class DocuSignHelper {
    public static Boolean isSkipSrDocTrigger = false; // Added by kuhinoor...
    /**-------------------------------------------------------------------
    * Description: used to filter the sr docs to send for e- signature 
    * -------------------------------------------------------------------**/
        public static void docusignBulktFilter(set<string> srDocIdSet) {
            HexaBPM__SR_Doc__c srDocToSend = new HexaBPM__SR_Doc__c();
            HexaBPM__SR_Doc__c srDocFroStpClose = new HexaBPM__SR_Doc__c();
            for (HexaBPM__SR_Doc__c srDoc : [SELECT id,Docusign_Envelope_Id__c,HexaBPM__Document_Master__r.HexaBPM__Code__c,
                                             Send_For_E_Signature__c,HexaBPM__Step__c,HexaBPM__Service_Request__c,
                                             HexaBPM__Service_Request__r.HexaBPM__Record_Type_Name__c
                                            FROM HexaBPM__SR_Doc__c WHERE id IN :srDocIdSet AND ( Send_For_E_Signature__c = TRUE or Docusign_Envelope_Id__c != null) LIMIT 1]){
                if(srDoc.Send_For_E_Signature__c){
                    srDocToSend = srDoc;
                }else if(srDoc.Docusign_Envelope_Id__c != NULL){
                    srDocFroStpClose = srDoc;
                }
            }
            if(srDocToSend.Id != null)
            {
                //Tharun changed below logic: ASF-1403 - This logic is executed from ContentDocumentLinkTriggerHandler after
                //creation of document by Nintex and attaching it to HexaBPM__SR_Doc__c
                //DocuSignHelper.sendUsingDocuSignFuture(srDocToSend.HexaBPM__Service_Request__c,srDocToSend.HexaBPM__Step__c,srDocToSend.HexaBPM__Document_Master__r.HexaBPM__Code__c);
                if(srDocToSend.HexaBPM__Service_Request__r.HexaBPM__Record_Type_Name__c == ALD_Constants.Agency_Re_Registration_DEV_RT){
                    AgencyRegDocuSignHelper.sendUsingDocuSignFuture(srDocToSend.HexaBPM__Service_Request__c,srDocToSend.HexaBPM__Step__c,srDocToSend.HexaBPM__Document_Master__r.HexaBPM__Code__c);
                }else{
                    DocuSignHelper.sendUsingDocuSignFuture(srDocToSend.HexaBPM__Service_Request__c,srDocToSend.HexaBPM__Step__c,srDocToSend.HexaBPM__Document_Master__r.HexaBPM__Code__c);
                }
                //Tharun changed above logic:ASF-1403
            }
            if(srDocFroStpClose.Id != null){
                System.Debug('Docusign_Envelope_Id__c----'+srDocFroStpClose.Docusign_Envelope_Id__c);
                closeRelatedStp(srDocFroStpClose.Docusign_Envelope_Id__c, false);
            }
        }
        
        /**-------------------------------------------------------------------
        * Description: future method to send the sr doc for e-signature collection 
        * -------------------------------------------------------------------**/
        @future(callout=true)
        public static void sendUsingDocuSignFuture(string srId, string stepId, string docCode ) {
            DocuSignHelper.sendUsingDocuSign(srId,stepId,docCode);
        }
        
        /**-------------------------------------------------------------------
        * Description: future method to send the sr doc for e-signature collection 
        * -------------------------------------------------------------------**/
        public static void sendUsingDocuSign(string srId, string stepId, string docCode ) {
            //declaration of variables
            List<dfsle.Recipient> recipientList = new List<dfsle.Recipient>();
            HexaBPM__SR_Doc__c relSrDoc = new HexaBPM__SR_Doc__c();
            string stepIdToLink;
            HexaBPM__Step__c relStp = new HexaBPM__Step__c();
            HexaBPM__Service_Request__c srObj = new HexaBPM__Service_Request__c();
            Map<string, string> signedCopyMap = new Map<string, string>{'Agency_Agreement_Document' => 'AgencyAgreementSignedbyAgency','AgencyAgreementSignedbyAgency'=>'AgencyAgreementSignedbyHeadofBM','AgencyAgreementSignedbyHeadofBM'=>'AgencyAgreementSignedbyCCO'};
            string relatedType;
            //get srDocs
            Set<id> contDocIdToSend = new Set<id>();
            Set<id> contVersionIdToSend = new Set<id>();
            HexaBPM__SR_Doc__c signedCopyPlaceholder = new HexaBPM__SR_Doc__c(); 
            HexaBPM__SR_Doc__c srDocToSend = new HexaBPM__SR_Doc__c(); 
            List<String> docCodeToSend = new list<String>{docCode,signedCopyMap.get(docCode)};
            for (HexaBPM__SR_Doc__c srDoc : [ SELECT id, HexaBPM__Document_Master__r.HexaBPM__Code__c,HexaBPM__Doc_ID__c
                                                FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: srId AND HexaBPM__Document_Master__r.HexaBPM__Code__c IN: docCodeToSend]) {
                if(srDoc.HexaBPM__Document_Master__r.HexaBPM__Code__c == docCode){
                    contDocIdToSend.add(srDoc.HexaBPM__Doc_ID__c);
                    srDocToSend = srDoc;
                }
                if(srDoc.HexaBPM__Document_Master__r.HexaBPM__Code__c == signedCopyMap.get(docCode)){
                    signedCopyPlaceholder = srDoc;
                }                                
            }
            try{
                for (HexaBPM__Step__c relStpitr : [SELECT id,Step_Template_Code__c,HexaBPM__SR__r.HexaBPM__Record_Type_Name__c, HexaBPM__SR_Step__r.DocusignExpiryinDays__c
                                                   FROM HexaBPM__Step__c WHERE id =:stepId]) {
                    relStp = relStpitr;
                }
                for (HexaBPM__Service_Request__c srObjItr : [SELECT id,HexaBPM__Customer__r.OwnerId,recordType.DeveloperName,
                                                             SignatoryName__c,SignatoryEmail__c FROM HexaBPM__Service_Request__c where id=: srId]) {
                    srObj = srObjItr; 
                }
                for (ContentVersion contVer : [SELECT Id from ContentVersion where ContentDocumentId IN: contDocIdToSend AND isLatest = true]) {
                    contVersionIdToSend.add(contVer.Id);
                }
                integer routingOrder = 1;
                
                if(relStp.Step_Template_Code__c == 'Digital Signature by Authorized Signatory'){
                    dfsle.Recipient envRecipient = createRecipientFromSobj(srObj,'SignatoryName__c','SignatoryEmail__c',srId,routingOrder,srId,null);
                    recipientList.add(envRecipient);
                }
                
                //query the internal signatories
                Map<string,sObject> internalSigMap = new Map<string,sObject>();
                for (sObject intSig : [select MasterLabel,EmailAddress__c,FullName__c,DeveloperName from InternalSignatories__mdt]) {
                    string DeveloperName = (string)intSig.get('DeveloperName'); 
                    if(relStp.Step_Template_Code__c == 'Digital Signature by Head of Broker Management' && DeveloperName == 'HeadOfBrokerManagement'){
                        internalSigMap.put(DeveloperName, intSig);
                    }else if(relStp.Step_Template_Code__c == 'Digital Signature by CCO' && DeveloperName == 'CCO'){ internalSigMap.put(DeveloperName, intSig);
                    }
                    
                }
                
                for (string recipientKey : internalSigMap.keySet()) {
                    dfsle.Recipient intEnvRecipient = createRecipientFromSobj(internalSigMap.get(recipientKey),'FullName__c','EmailAddress__c',recipientKey,routingOrder,srId,null);
                    recipientList.add(intEnvRecipient);
                    routingOrder += 1;
                }
                
                dfsle.Envelope envelope;
                //If  <TO get the expiry from SR level + add withNotifivcations conditionally>
                if(relStp.HexaBPM__SR_Step__r.DocusignExpiryinDays__c !=null ){
                    dfsle.Notifications notifyRecipients = new dfsle.Notifications(false,0,0,true,Integer.ValueOf(relStp.HexaBPM__SR_Step__r.DocusignExpiryinDays__c),0,false );
                    envelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(srId)).withRecipients(recipientList)
                    .withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(),contVersionIdToSend)).withNotifications(notifyRecipients) ;
                
                }else{
                    envelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(srId)).withRecipients(recipientList).withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(),contVersionIdToSend)) ;
                }
                
                try{    
                    envelope = test.isRunningTest()?null:dfsle.EnvelopeService.sendEnvelope(envelope, true);
                }catch(DMLException ex) { insert new Logger__c(ClassName__c = 'Docusign Helper',Message__c = 'Exception on sendEnvelope  :'+ex.getMessage() + ex.getStackTraceString());
                }
                string DocuSignID = test.isRunningTest()?'Test':String.valueOf(envelope.docuSignId);
                
                if (DocuSignID != null) {
                    //update the sr doc to attach the signed envelope
                    if (signedCopyPlaceholder.Id != null) {
                        signedCopyPlaceholder.Docusign_Envelope_Id__c = DocuSignID;
                        update signedCopyPlaceholder;
                    }
                    
                    dfsle__Envelope__c envelopeToUpdate = new dfsle__Envelope__c();
                    dfsle__EnvelopeStatus__c envStatus = new dfsle__EnvelopeStatus__c();
                    
                    for (dfsle__Envelope__c envObj : [ SELECT id FROM dfsle__Envelope__c WHERE dfsle__DocuSignId__c = :DocuSignID]) {
                        envelopeToUpdate = envObj;
                    }
                    if (envelopeToUpdate.id != null) {
                        envelopeToUpdate.Step__c = stepId;
                        envelopeToUpdate.Service_Request__c = srId;
                        update envelopeToUpdate;
                    }
            
                }
            }catch(Exception ex){ insert new Logger__c(ClassName__c = 'CC_SendDocuSignEnv Error',Message__c = 'Exception on CC_SendDocuSignEnv  :'+ex.getMessage() + ex.getStackTraceString());
            }
            if(srDocToSend != null && srDocToSend.Id != null){
                srDocToSend.Send_For_E_Signature__c = false;
                update srDocToSend;
            }
        }
        
        public static dfsle.Recipient createRecipientFromSobj(SObject recepient, string NameField, string emailField, string stacticAchorTab, integer routingOrder, string srId, string type) {
                                                                  
            string recepientName = string.valueof(recepient.get(NameField));
            string recepientEmail = string.valueof(recepient.get(emailField));
            
            return createRecipientFromSobj(recepientName, recepientEmail, stacticAchorTab, routingOrder, srId, type);                                                            
        }

        public static dfsle.Recipient createRecipientFromSobj(string recepientName, string recepientEmail, string stacticAchorTab, integer routingOrder, string srId, string type) {
                                                                  
            // string recepientName = string.valueof(recepient.get(NameField));
            // string recepientEmail = string.valueof(recepient.get(emailField));
            string recepientNameTruncated = recepientName.length() < 80 ? recepientName : recepientName.substring(0,79);
            //string anchorString = String.isNotEmpty(stacticAchorTab) ? stacticAchorTab : recepientEmail;
            string anchorString = stacticAchorTab;
            dfsle.Tab signatureTab = createEnvTab(anchorString + 'SignatureHolder');
            dfsle.Tab dateTab = createEnvTab(anchorString + 'DateHolder');
            dfsle.Tab initialHereTab = createEnvTab(anchorString + 'InitialsHolder');
            dfsle.Tab stampTab = createEnvTab(anchorString + 'StampHolder');
                                                                  
            //string SourceId = hasSObjectField('Id', recepient) ? string.valueof(recepient.get('Id')) : srId;
            
            dfsle.Recipient envRecipient = dfsle.Recipient.fromSource(recepientName, recepientEmail, null, 
                                                                    null, new dfsle.Entity(srId))
                .withTabs(new List<dfsle.Tab> {signatureTab,dateTab,initialHereTab,stampTab})
                .withRoutingOrder(routingOrder);  
            
            if(type != null){ envRecipient = envRecipient.withType(type);
            } 
            
            return envRecipient;                                                            
        }
    
        public static String sendSRDocForESign(HexaBPM__SR_Doc__c srDoc, List<HexaBPM__SR_Doc__c> signDocument, List<String> eSignGroupList, String authorisedSignatory) {
            try {
                System.debug('srDoc.Id>>> ' + srDoc.Id);
                Id documentToContentVersionId = !Test.isRunningTest() ? srDoc.ContentDocumentLinks[0].ContentDocument.LatestPublishedVersionId : null;
                String recordTypeName = [SELECT Name, RecordType.DeveloperName FROM HexaBPM__Service_Request__c WHERE Id =:srDoc.HexaBPM__Service_Request__c LIMIT 1].RecordType.DeveloperName;
                
                List<dfsle.Recipient> recipientList = new List<dfsle.Recipient>();
                Integer routingOrder = 1;
                System.debug('@@@eSignGroupList '+eSignGroupList);
                 System.debug('@@@SR Record '+srDoc.HexaBPM__Service_Request__c);
                System.debug('@@@srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__c '+srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__c);
                System.debug('@@@srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__c '+srDoc.HexaBPM__Service_Request__r.BuyerName__c);
                
                //seller recipient
                if (eSignGroupList.contains(Constants.CUSTOMER_ESIGN) && srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__c != null) {
                    String name = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.Name;
                    String email = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail != null ? srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail : srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.Email__c;
                    String recipientKey = srDoc.Id + '' + srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__c;
                    System.debug('Customer Email>>>' + email); 

                    recipientList.add(createRecipientFromSobj(name, email, recipientKey, routingOrder, srDoc.Id, null));
                    routingOrder += 1;
                }
                
                //Seller Joint owner
                if (eSignGroupList.contains(Constants.CUSTOMER_WITH_JOINT_OWNER_ESIGN) && String.isNotBlank(srDoc.HexaBPM__Service_Request__c) && String.isNotBlank(srDoc.HexaBPM__Service_Request__r.SalesOrder__c)) {
                    List<JointOwner__c> JointSellerList = [ SELECT Id, Account__c, Account__r.PersonEmail, Account__r.name FROM JointOwner__c WHERE salesorder__c = : srDoc.HexaBPM__Service_Request__r.SalesOrder__c];
                    if( JointSellerList != null && JointSellerList.size() > 0 ){
                        for (JointOwner__c sellerObj : JointSellerList ) {
                            String recipientKey = srDoc.Id +''+ sellerObj.Account__c; 
                            recipientList.add(createRecipientFromSobj(sellerObj.Account__r.name , sellerObj.Account__r.PersonEmail, recipientKey, routingOrder, srDoc.Id, null));
                            routingOrder += 1;
                        }
                    }
                }
				//Buyer Recipient
                if (eSignGroupList.contains(Constants.BUYER_ESIGN) && srDoc.HexaBPM__Service_Request__r.BuyerName__c != null) {
                    String name = srDoc.HexaBPM__Service_Request__r.BuyerName__r.Name;
                    String email = srDoc.HexaBPM__Service_Request__r.BuyerName__r.PersonEmail != null ? srDoc.HexaBPM__Service_Request__r.BuyerName__r.PersonEmail : srDoc.HexaBPM__Service_Request__r.BuyerName__r.Email__c;
                    System.debug('Buyer Email>>>' + email);
                    String recipientKey = srDoc.Id + '' + srDoc.HexaBPM__Service_Request__r.BuyerName__c;

                    recipientList.add(createRecipientFromSobj(name, email, recipientKey, routingOrder, srDoc.Id, null));
                    routingOrder += 1;
                }
                
                // Buyer with joint owner added by kuhinoor...
                if (eSignGroupList.contains(Constants.BUYER_WITH_JOINT_OWNER_ESIGN) && String.isNotBlank(srDoc.HexaBPM__Service_Request__c)) {
                    List<AgencyTeam__c> JointBuyerList = [ SELECT Id, Account__c, Account__r.PersonEmail, Account__r.name   FROM AgencyTeam__c WHERE ServiceRequest__c = : srDoc.HexaBPM__Service_Request__c];
                    if( JointBuyerList != null && JointBuyerList.size() > 0 ){
                        for (AgencyTeam__c buyerObj : JointBuyerList ) {
                            String recipientKey = srDoc.Id +''+ buyerObj.Account__c; 
                            recipientList.add(createRecipientFromSobj(buyerObj.Account__r.name , buyerObj.Account__r.PersonEmail, recipientKey, routingOrder, srDoc.Id, null));
                            routingOrder += 1;
                        }
                    }
                }
                
                /* Below code is commented by Tharun  as per Rizwan
                if(srDoc.Name == ALD_Constants.DOCUMENT_D_AND_T_MEMO && recordTypeName == Constants.DEFAULT_AND_TERMINATION_DEV_RT) {
                    
                    if(srDoc.HexaBPM__Service_Request__r?.Unit__r.Project__r?.Development_Manager_Email__c != null) {
                        String managerEmail = srDoc.HexaBPM__Service_Request__r.Unit__r.Project__r.Development_Manager_Email__c;
                        String reciKey = managerEmail;
                        recipientList.add(createRecipientFromSobj(managerEmail, managerEmail, reciKey, routingOrder, srDoc.Id, null));
                        routingOrder += 1;
                    }

                    for(Aldar_Signatory_for_Post_Sales__mdt intSig : [SELECT Id, Email__c, Is_Active__c, Order_Number__c, SR_Type__c, DeveloperName FROM Aldar_Signatory_for_Post_Sales__mdt WHERE Is_Active__c = true ORDER BY Order_Number__c ASC]) {
                        String recipientKey = srDoc.Id + intSig.DeveloperName;
                        recipientList.add(createRecipientFromSobj(intSig.Email__c, intSig.Email__c, recipientKey, routingOrder, srDoc.Id, null));
                        routingOrder += 1;
                    }
                }
                Above code is commented by Tharun as per Rizwan */
                
                //NOC_BROKER_LETTER check is added by Tharun BPE-87
                if(srDoc.DocumentMasterCode__c == ALD_Constants.NOC_Broker_Letter && recordTypeName == ALD_Constants.Agency_Registration_DEV_RT)
                {
                    for(InternalSignatories__mdt intSig : [SELECT MasterLabel, EmailAddress__c, FullName__c, DeveloperName FROM InternalSignatories__mdt WHERE DeveloperName = 'ValidationOfBrokers']) {
                        String recipientKey = srDoc.Id + intSig.DeveloperName;
                        recipientList.add(AgencyRegDocuSignHelper.createRecipientFromSobj(intSig.FullName__c, intSig.EmailAddress__c, recipientKey, routingOrder, srDoc.Id, 'Approver'));
                        routingOrder += 1;
                    }
                }
				//NOC_BROKER_LETTER check is added by Tharun BPE-87
                
                
                if (eSignGroupList.contains(Constants.AUTHORISED_SIGNATORY_ESIGN) && String.isNotBlank(authorisedSignatory)) {
                    List<String> authorisedSignatoryList = authorisedSignatory.split(',');
                    for (InternalSignatories__mdt intSig: [SELECT Id, MasterLabel, DeveloperName, FullName__c, EmailAddress__c, Type__c, OrderNo__c FROM InternalSignatories__mdt WHERE Type__c =: srDoc.HexaBPM__Service_Request__r.RecordType.Name AND EmailAddress__c IN: authorisedSignatoryList ORDER BY OrderNo__c]) {
                        String recipientKey = srDoc.Id + intSig.DeveloperName;
                        System.debug('Authorised Signatory>>>' + intSig.EmailAddress__c);
                        recipientList.add(createRecipientFromSobj(intSig.FullName__c, intSig.EmailAddress__c, recipientKey, routingOrder, srDoc.Id, null));
                        routingOrder += 1; 
                    }
                }
                
                // Esign Logic
                // Create an envelope with the DocID and Add Recipient & Document.
                dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(srDoc.Id)).withRecipients(recipientList).withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(), new Set<Id>{documentToContentVersionId}));
                // dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(srDoc.Id)).withRecipients(recipientList).withDocuments(new List<dfsle.Document> {dfsle.Document.fromTemplate(dfsle.UUID.parse(template), description)});

                // Add document to the Envelope
                myEnvelope = test.isRunningTest() ? null : dfsle.EnvelopeService.sendEnvelope(myEnvelope, true);

                //Docusign Envelop Id
                String DocuSignId = test.isRunningTest() ? 'Test' : String.valueOf(myEnvelope.docuSignId);
                  
                List<HexaBPM__SR_Doc__c> updatesrsigndocument = new List<HexaBPM__SR_Doc__c>();
                for(HexaBPM__SR_Doc__c signsrdoc:signDocument)
                {

                signsrdoc.Docusign_Envelope_Id__c = DocuSignId;
                updatesrsigndocument.add(signsrdoc);
                }
                
                
                update updatesrsigndocument; return Constants.SUCCESS_MESSAGE;
            } 
           catch(Exception e) {
                return e.getMessage();
            }
        }
        
        public static dfsle.Tab createEnvTab(string anchorString ) {
            dfsle.Tab envTab;
            dfsle.Tab.Anchor anchor = new dfsle.Tab.Anchor(
                anchorString, // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'right', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                -60, // X offset
                15);
            
            dfsle.SignHereTab.StampImage img = new dfsle.SignHereTab.StampImage('signature_image',null,null,null,true);
            dfsle.SignHereTab.Stamp Stamp = new dfsle.SignHereTab.Stamp('stamp',null,'NameHanko','test','test',img,null,null);
            
            if(anchorString.contains('SignatureHolder')){
                envTab = new dfsle.SignHereTab().withAnchor(anchor);
            }else if(anchorString.contains('DateHolder')){
                envTab = new dfsle.DateSignedTab().withAnchor(anchor);
            }else if(anchorString.contains('InitialsHolder')){
                envTab = new dfsle.InitialHereTab().withAnchor(anchor);
            }else if(anchorString.contains('StampHolder')){
                envTab = new dfsle.SignHereTab().withStamp(Stamp).withAnchor(anchor);
            }
            return envTab;
        }
        
        public static boolean hasSObjectField(String fieldName, SObject so){
            String s = JSON.serialize(so);
            // Deserialize it back into a key/value map
            Map<String,Object> obj = (Map<String,Object>) JSON.deserializeUntyped(s);
            // Build a set containing the fields present on our SObject
            Set<String> fieldsPresent = obj.keyset().clone();
            return fieldsPresent.contains(fieldName);
        }
        
        public static void closeRelatedStp(String evnelopeId, boolean isReject){
            string stpIdToClose;
            dfsle__Envelope__c envObj = new dfsle__Envelope__c();
            for (dfsle__Envelope__c envObjItr : [select id,Step__c,Service_Request__c from dfsle__Envelope__c WHERE dfsle__DocuSignId__c =: evnelopeId]) {
                envObj = envObjItr;
            }
            if(envObj.Step__c != null){
                HexaBPM__Step__c stp = new HexaBPM__Step__c();
                for(HexaBPM__Step__c stepObjItr : [SELECT id,HexaBPM__SR__c,HexaBPM__SR_Step__c,HexaBPM__Status__c, Step_Template_Code__c,HexaBPM__Status__r.HexaBPM__Type__c  from HexaBPM__Step__c WHERE id=: envObj.Step__c]){
                    stp = stepObjItr;
                }  
                if(stp.HexaBPM__Status__r.HexaBPM__Type__c != 'End'){
                    HexaBPM__Service_Request__c objSR = new HexaBPM__Service_Request__c(Id = envObj.Service_Request__c);
                    HexaBPM__Step_Transition__c relatedtransition = new HexaBPM__Step_Transition__c();
                    
                    for (HexaBPM__Step_Transition__c stptran : [ SELECT Id,HexaBPM__SR_Status_Internal__c,HexaBPM__SR_Status_External__c,HexaBPM__Transition__r.HexaBPM__To__c,HexaBPM__Transition__r.HexaBPM__From__c,
                                                                HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Type__c, HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Rejection__c FROM HexaBPM__Step_Transition__c  WHERE HexaBPM__Transition__c != NULL AND HexaBPM__SR_Step__c = :stp.HexaBPM__SR_Step__c
                                                                AND HexaBPM__Transition__r.HexaBPM__From__c = :stp.HexaBPM__Status__c AND HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Type__c = 'End' AND HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Reupload_Document__c = FALSE]) {
                                                                    
                        if(isReject == true && stptran.HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Rejection__c == TRUE){relatedtransition = stptran;
                        }else if(stptran.HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Rejection__c == FALSE){relatedtransition = stptran;}
                    }
                    
                    if (relatedtransition.Id != null) {
                        stp.HexaBPM__Status__c = relatedtransition.HexaBPM__Transition__r.HexaBPM__To__c;
                        if (relatedtransition.HexaBPM__SR_Status_Internal__c != null) objSR.HexaBPM__Internal_SR_Status__c = relatedtransition.HexaBPM__SR_Status_Internal__c;
                        if (relatedtransition.HexaBPM__SR_Status_External__c != null) objSR.HexaBPM__External_SR_Status__c = relatedtransition.HexaBPM__SR_Status_External__c;
                    }
                    
                    try {
                        update stp;
                        if (objSR.HexaBPM__Internal_SR_Status__c != null || objSR.HexaBPM__External_SR_Status__c != null){ update objSR;
                        }
                        
                    } catch (Exception ex) { insert new Logger__c(ClassName__c = 'Docusign Helper',Message__c='Exception on closeRelatedStp  :'+ex.getMessage() + ex.getStackTraceString());
                    } 
                }
            }  
        }
    }