/**********************************************************************************************************************
* Name              : AgencyRegDocuSignHelper                                                        
* Description       : This apex class is specially for Agency Re-Registration SR Process
* Created By & Date : tdontha@aldar.com - Tharun [20-Aug-2023]
* Last Modified By	: tdontha@aldar.com - Tharun [25-Aug-2023]
******************************************************************************************************************/
public without sharing class AgencyRegDocuSignHelper
{
    @AuraEnabled
    public static String getStepDetails(String srId){
        
        String TEMPLATE_CODE = 'Digital Signature by Authorized Signatory';
        String returnStepId = '';
        List<HexaBPM__Step__c> stepList = [SELECT id, Name, SRTemplateName__c, Step_Template_Code__c 
                                           FROM HexaBPM__Step__c 
                                           WHERE HexaBPM__SR__c =: srId  
                                           AND Step_Template_Code__c = :TEMPLATE_CODE LIMIT 1];
        if(!stepList.isEmpty()){
            returnStepId = stepList[0].Id;
        }
        return returnStepId;
    }
    
    @AuraEnabled
    @future(callout=true)
    public static void sendUsingDocuSignFuture(string srId, string stepId, string docCode){
        sendUsingDocuSign(srId,stepId,docCode);
    }
    
    public static void sendUsingDocuSign(string srId, string stepId, string docCode){
        //declaration of variables
        List<dfsle.Recipient> recipientList 		= new List<dfsle.Recipient>();
        HexaBPM__Step__c relStp 					= new HexaBPM__Step__c();
        HexaBPM__Service_Request__c srObj 			= new HexaBPM__Service_Request__c();
        Map<string, string> signedCopyMap 			= new Map<string, string>{'Agency_Agreement_Document' => 'AgencyAgreementSignedbyHeadofBM'};
        List<String> docCodeToSend 					= new list<String>{docCode,signedCopyMap.get(docCode)};
        Set<id> contDocIdToSend 					= new Set<id>();
        Set<id> contVersionIdToSend 				= new Set<id>();
        HexaBPM__SR_Doc__c signedCopyPlaceholder 	= new HexaBPM__SR_Doc__c(); 
        HexaBPM__SR_Doc__c srDocToSend 				= new HexaBPM__SR_Doc__c(); 
        
        for(HexaBPM__SR_Doc__c srDoc : [SELECT Id,HexaBPM__Document_Master__r.HexaBPM__Code__c, HexaBPM__Doc_ID__c
                                        FROM HexaBPM__SR_Doc__c 
                                        WHERE HexaBPM__Service_Request__c =: srId 
                                        AND HexaBPM__Document_Master__r.HexaBPM__Code__c IN: docCodeToSend])
        {
            if(srDoc.HexaBPM__Document_Master__r.HexaBPM__Code__c == docCode){
                contDocIdToSend.add(srDoc.HexaBPM__Doc_ID__c);
                srDocToSend = srDoc;
            }
            if(srDoc.HexaBPM__Document_Master__r.HexaBPM__Code__c == signedCopyMap.get(docCode)){
                signedCopyPlaceholder = srDoc;
            }                                
        }
        try{
            Integer routingOrder = 1;
            dfsle.Envelope envelope;
            for(HexaBPM__Step__c relStpitr : [SELECT Id,Step_Template_Code__c,HexaBPM__SR__r.HexaBPM__Record_Type_Name__c,
                                              HexaBPM__SR_Step__r.DocusignExpiryinDays__c
                                              FROM HexaBPM__Step__c WHERE id =:stepId]){
                relStp = relStpitr;
            }
            for(HexaBPM__Service_Request__c srObjItr : [SELECT id,HexaBPM__Customer__r.OwnerId,recordType.DeveloperName,
                                                        SignatoryName__c,SignatoryEmail__c 
                                                        FROM HexaBPM__Service_Request__c where id=: srId]){
                srObj = srObjItr; 
            }
            for (ContentVersion contVer : [SELECT Id FROM ContentVersion 
                                           WHERE ContentDocumentId IN: contDocIdToSend AND isLatest = true]){
                contVersionIdToSend.add(contVer.Id);
            }
            System.debug('@@@srObj---->'+srObj);
            
            if(relStp.Step_Template_Code__c == 'Digital Signature by Authorized Signatory'){
                //routingOrder == 1
                dfsle.Recipient brokerRecipient = createRecipientFromSobj(srObj,'SignatoryName__c','SignatoryEmail__c',srId,routingOrder,srId,'Signer');
                recipientList.add(brokerRecipient);
            }
            
            //Query the internal signatories & approvers for Agency Registration
            Map<string,sObject> internalSigMap = new Map<string,sObject>();
            for (sObject intSig : [SELECT MasterLabel, EmailAddress__c, FullName__c, DeveloperName , OrderNo__c
                                   FROM InternalSignatories__mdt 
                                   WHERE Type__c = 'Agency Registration' 
                                   ORDER BY OrderNo__c ASC]) 
            {
                String DeveloperName = (String)intSig.get('DeveloperName');
                if(DeveloperName == 'HeadOfBrokerManagement' || DeveloperName == 'ValidationOfBrokers'){
                    internalSigMap.put(DeveloperName, intSig);
                }
            }
            
            for (string recipientKey : internalSigMap.keySet()){
                routingOrder += 1;
                String signtype = (recipientKey == 'HeadOfBrokerManagement') ? 'Signer' : 'Approver';
                dfsle.Recipient intRecipient = createRecipientFromSobj(internalSigMap.get(recipientKey),'FullName__c','EmailAddress__c',recipientKey,routingOrder,srId,signtype);
                recipientList.add(intRecipient);
            }
            System.debug('DocusignExpiryinDays__c--->'+relStp.HexaBPM__SR_Step__r.DocusignExpiryinDays__c);
            
            if(relStp.HexaBPM__SR_Step__r.DocusignExpiryinDays__c !=null ){
                dfsle.Notifications notifyRecipients = new dfsle.Notifications(false,0,0,true,Integer.ValueOf(relStp.HexaBPM__SR_Step__r.DocusignExpiryinDays__c),0,false );
                envelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(srId)).withRecipients(recipientList)
                    .withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(),contVersionIdToSend)).withNotifications(notifyRecipients) ;
            }else{
                envelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(srId)).withRecipients(recipientList)
                    .withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(),contVersionIdToSend));
            }
            
            try{   
                envelope = test.isRunningTest()?null:dfsle.EnvelopeService.sendEnvelope(envelope, true);
            }catch(DMLException ex) { insert new Logger__c(ClassName__c = 'AgencyReg DocuSignHelper',Message__c = 'Exception on sendEnvelope  :'+ex.getMessage() + ex.getStackTraceString());}
            
            String DocuSignID = test.isRunningTest()?'Test':String.valueOf(envelope.docuSignId);
            if (DocuSignID != null){
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
        }catch(Exception ex){ insert new Logger__c(ClassName__c = 'AgencyReg_DocuSignHelper Error',Message__c = 'Exception on AgencyReg_DocuSignHelper  :'+ex.getMessage() + ex.getStackTraceString());}
        if(srDocToSend != null && srDocToSend.Id != null){
            srDocToSend.Send_For_E_Signature__c = false;
            update srDocToSend;
        }
    }
    
    public static dfsle.Recipient createRecipientFromSobj(SObject recepient, string NameField, string emailField, 
                                                          string stacticAchorTab, integer routingOrder, string srId, 
                                                          string signerType){
        string recepientName = string.valueof(recepient.get(NameField));
        string recepientEmail = string.valueof(recepient.get(emailField));
        return createRecipientFromSobj(recepientName, recepientEmail, stacticAchorTab, routingOrder, srId, signerType);                                                            
    }
    
    public static dfsle.Recipient createRecipientFromSobj(string recepientName, string recepientEmail, 
                                                          string stacticAchorTab, integer routingOrder, 
                                                          string srId, string signerType){
        string recepientNameTruncated = recepientName.length() < 80 ? recepientName : recepientName.substring(0,79);
        string anchorString = stacticAchorTab;
        dfsle.Recipient envRecipient;
        dfsle.Tab signatureTab = createEnvTab(anchorString + 'SignatureHolder');
        dfsle.Tab dateTab = createEnvTab(anchorString + 'DateHolder');
        dfsle.Tab initialHereTab = createEnvTab(anchorString + 'InitialsHolder');
        dfsle.Tab stampTab = createEnvTab(anchorString + 'StampHolder');
        
        if(signerType == 'Signer'){
            envRecipient = dfsle.Recipient.fromSource(recepientName, recepientEmail, null, 
                                                      null, new dfsle.Entity(srId))
                .withTabs(new List<dfsle.Tab> {signatureTab,dateTab,initialHereTab,stampTab})
                .withRoutingOrder(routingOrder);
        }else if(signerType == 'Approver'){
            dfsle.Tab myApproveTab = new dfsle.ApproveTab().withPosition(new dfsle.Tab.Position(
                1, // The document to use
                1, // Page number on the document
                210, // X position
                105, // Y position
                100, // 100 pixels wide
                null)); // Default height
            dfsle.Tab myDeclineTab = new dfsle.DeclineTab().withPosition(new dfsle.Tab.Position(
                1, // The document to use
                1, // Page number on the document
                210, // X position
                155, // Y position
                100, // 100 pixels wide
                null)); // Default height
            envRecipient = dfsle.Recipient.fromSource(recepientName,recepientEmail,
                                                      null, // Optional phone number
                                                      'Broker Admin', // Role Name. Specify the exact role name from template
                                                      new dfsle.Entity(srId))
                .withTabs(new List<dfsle.Tab> {signatureTab,dateTab,initialHereTab,myApproveTab,myDeclineTab}).withRoutingOrder(routingOrder); // Source object for the Recipient
        }
        return envRecipient;                                                           
    }
    
    public static dfsle.Tab createEnvTab(string anchorString){
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
    
}