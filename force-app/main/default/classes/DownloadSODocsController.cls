/**********************************************************************************************************************
* Name               : DownloadSODocsController                                                        
* Description        : Class to get all the document Ids, also used to send the documents for eSign
* Usage              : DownloadSODocs,sendFoESign LWC (Used in Portal)                                                     
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  	Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     	06/06/2022      Initial Draft 
* 2.0  			Muzammil Bajaria			26/11/2022		Updated for QES signature
******************************************************************************************************************/
public with sharing class DownloadSODocsController {
    /**
* fetchAllDocumentIDs
*
* This method used to return standard download url
*
* @param  recordId salesOrder recordId
* @return string standard download url
*/
    @AuraEnabled(cacheable=false)
    public static string fetchAllDocumentIDs(String recordId){
         System.debug(recordId);
        list<string> IdList = new list<String>();
        String likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_SIGNED+'%';
        for(contentDocumentLink tempRec : [select id, ContentDocumentId,contentDocument.LatestPublishedVersionId from contentDocumentLink where linkedEntityId in (select id from Document__c where SalesOrder__c = :recordId and (not DocumentType__c like :likedSignedString ))]){
            IdList.add(tempRec.contentDocument.LatestPublishedVersionId);
        }
        if(!IdList.isEmpty()){ return '/sfc/servlet.shepherd/version/download/'+ String.Join(IdList,'/');
                             }
        return null;
    }
    
    /**
* getDocumentDetails
*
* Method used to get document details. Used to send before signature.
*
* @param  recordId salesOrder recordId
*/
    @AuraEnabled(cacheable=false)
    public static Document__c getDocumentDetails(String recordId){
        return [SELECT Id,Identityverification__c FROM Document__c WHERE Id=:recordId];
    }
    
    /**
* regenerateAllDocuments
*
* This method used to regenerate all the missing placeholder and update the generate flag to true
*
* @param  recordId salesOrder recordId
* @return string standard download url
*/
    @AuraEnabled(cacheable=false)
    public static string regenerateAllDocuments(String recordId){
        string messageToReturn = Constants.SUCCESS_MESSAGE;
        //try{
        DocumentService.regenerateAllDocuments(recordId);
        //}catch(Exception e){messageToReturn = e.getMessage();}
        return messageToReturn;
    }
    
    
    /**
* sendForESign
*
* This method used to send the selected Document for e Signature manually
*
* @param  recordId salesOrder recordId
* @return string standard download url
*/
    @AuraEnabled(cacheable=false)
    public static string sendForESign(String recordId){
        system.debug(recordId); 
        try{
            //Verification for account
            list<Document__c> documentRecord = [select id,Identityverification__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.Unit__r.Project__c,
                                                SalesOrder__r.Unit__r.Project__r.Name,DocumentType__c,SalesOrder__c,ExpressionofInterest__c,
                                                SalesOrder__r.Account__c,ExpressionofInterest__r.Account__c,Account__c,DocuSignedDateTime__c,
                                                Case__c, Case__r.SalesOrder__c, Case__r.AccountId, Case__r.RecordType.DeveloperName,Sales_Order_Relationship__c, Sales_Order_Relationship__r.Account__c,
                                                Sales_Order_Relationship__r.Customer_Account__c, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName, Opportunity__r.BuyerComplianceStatus__c,
                                                ProjectName__c,Document_Verified__c,SalesOrder__r.Unit__r.Project__r.City__c,SPAValidation__c from Document__c where id= :recordId limit 1 ];
            // Updated SOQL by Moh Sarfaraj for ASF-1799
            // Updated SOQL by Moh Sarfaraj for ASF-1185 on 24 July 2023
            // Updated SOQL by Yenshuldeep for Resale Documents on 11 Sept, 2023 
            
            /*    AggregateResult groupResults = [Select SalesOrder__r.Unit__r.Project__r.Name,SUM(SalesOrder__r.NetAmount__c)netAmount
                                             FROM Document__c where SalesOrder__r.ProjectName__c =:documentRecord[0].SalesOrder__r.Unit__r.Project__c
                                             AND SalesOrder__r.Status__c !='Cancelled' 
                                             AND Identityverification__c = true 
                                             AND Esignlocation__c != '' 
                                             GROUP BY SalesOrder__r.Unit__r.Project__r.Name];
            
          AggregateResult groupResults = [SELECT 
                                             Unit__r.Project__c,
                                             SUM(NetAmount__c)netAmount
                                             FROM SalesORder__c
                                             WHERE Unit__r.Project__c =: documentRecord[0].SalesOrder__r.Unit__r.Project__c
                                             GROUP BY Unit__r.Project__c];
            */
            map<id,id> documentToContentVersionID = new map<id,id>();
            for(ContentDocumentLink conDocLink : [select id,ContentDocumentId,ContentDocument.LatestPublishedVersionId,LinkedEntityId from ContentDocumentLink where LinkedEntityId = :recordId order by ContentDocument.CreatedDate DESC ]){
                documentToContentVersionID.put(conDocLink.LinkedEntityId,conDocLink.ContentDocument.LatestPublishedVersionId);
            }
         
          
            if(!documentRecord.isEmpty() && !documentToContentVersionID.isEmpty()){
                
                // Added by Moh Sarfaraj for ASF-1185 on 24 July 2023 start
                // Updated by Moh Sarfaraj for ASF-1799
                List<String> listDocumentType = new List<String>(Label.Document_Type.split(','));
                if(String.isNotBlank(documentRecord[0].ProjectName__c)){ if(((!documentRecord[0].Document_Verified__c && listDocumentType[0].equalsIgnoreCase(documentRecord[0].DocumentType__c)) || (!documentRecord[0].SPAValidation__c && listDocumentType[1].equalsIgnoreCase(documentRecord[0].DocumentType__c))) && documentRecord[0].ProjectName__c.equalsIgnoreCase(Label.ADHAProject)){ return 'Document Unverified'; }} 
                // Added by Moh Sarfaraj for ASF-1185 on 24 July 2023 end
            
                Id relatedAccountId;
                Id relatedsObjectId;
                String recipitEmail='';
                String oppComplianceStatus = '';
                Boolean isResale = false;
                Boolean useDocuSignUtilityWrapper = false;
                list<Document__C> relatedSignDocument = new list<Document__C>(); 
               // String likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_SIGNED+' '+ documentRecord[0].DocumentType__c;
                String likedSignedString = '';
                if(documentRecord[0].Identityverification__c){ likedSignedString = 'Aldar Signed SPA'; } 
                else { likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_SIGNED+' '+ documentRecord[0].DocumentType__c; }
                if(documentRecord[0].Identityverification__c){
                    if(documentRecord[0].DocuSignedDateTime__c != null && system.now() < documentRecord[0].DocuSignedDateTime__c ){ return 'Please wait for 2 minutes!'; }
                }
                    /*else if(documentRecord[0].DocuSignedDateTime__c != null){
                    
                }
                    
                }*/
                if(documentRecord[0].SalesOrder__c !=null){
                    relatedsObjectId =documentRecord[0].SalesOrder__c;
                    relatedAccountId = documentRecord[0].SalesOrder__r.Account__c;
                    relatedSignDocument = [select id from Document__C where SalesOrder__c = :documentRecord[0].SalesOrder__c and  DocumentType__c = :likedSignedString];
                    //Added by Arvind - Only for Dubai City                   
                    if(documentRecord[0].ProjectName__c != null && documentRecord[0].SalesOrder__r.Unit__r.Project__r.City__c != null && documentRecord[0].SalesOrder__r.Unit__r.Project__r.City__c == 'Dubai'
                        && documentRecord[0].DocumentType__c.trim().equalsIgnoreCase(System.Label.IntentionToBook.trim()))

                    //if(documentRecord[0].ProjectName__c != null && documentRecord[0].ProjectName__c.trim().equalsIgnoreCase(System.Label.DubaiProject.trim())
                        //&& documentRecord[0].DocumentType__c.trim().equalsIgnoreCase(System.Label.IntentionToBook.trim()))
                    {
                            useDocuSignUtilityWrapper = true;
                        }
                }else if(documentRecord[0].ExpressionofInterest__c !=null ){
                    relatedsObjectId =documentRecord[0].ExpressionofInterest__c;  relatedAccountId = documentRecord[0].ExpressionofInterest__r.Account__c;
                    relatedSignDocument = [select id from Document__C where ExpressionofInterest__c = :documentRecord[0].ExpressionofInterest__c and  DocumentType__c = :likedSignedString];
                }else if(documentRecord[0].Case__c != null && documentRecord[0].Case__r.RecordType.DeveloperName.equalsIgnoreCase('Resale')){
                    relatedsObjectId =documentRecord[0].Case__r.AccountId;
                    relatedAccountId = documentRecord[0].Case__r.AccountId;
                    relatedSignDocument = [ SELECT Id FROM Document__c 
                                            WHERE Case__c =:documentRecord[0].Case__c 
                                                AND DocumentType__c =: likedSignedString];
                }else if(documentRecord[0].Opportunity__c != null && documentRecord[0].Opportunity__r.RecordType.DeveloperName.equalsIgnoreCase('Resale')){
                    relatedsObjectId =documentRecord[0].Opportunity__c;
                    relatedAccountId = documentRecord[0].Opportunity__r.AccountId; 
                      oppComplianceStatus = documentRecord[0].Opportunity__r.BuyerComplianceStatus__c == null ? '' : documentRecord[0].Opportunity__r.BuyerComplianceStatus__c ;
                    relatedSignDocument = [ SELECT Id FROM Document__c 
                                            WHERE Opportunity__c =:documentRecord[0].Opportunity__c 
                                                AND DocumentType__c =: likedSignedString];
                    isResale = true;
                    if(oppComplianceStatus != 'Cleared'){
                        return System.Label.ResaleComplianceErrorMessage;
                    }
                    // SSC-125 related changes by BASHIM: Send email for third party noc to third party account
                    // Start
                } else if(documentRecord[0].Sales_Order_Relationship__c != null){
                    relatedsObjectId = documentRecord[0].Sales_Order_Relationship__c;
                    relatedAccountId = documentRecord[0].Sales_Order_Relationship__r.Account__c;
                    relatedSignDocument = [SELECT Id FROM Document__c WHERE Sales_Order_Relationship__c = :documentRecord[0].Sales_Order_Relationship__c AND  DocumentType__c = :likedSignedString];
                    
                } // added by Cloudzlab for Secondary Market
                else if(documentRecord[0].Opportunity__c != null && documentRecord[0].Opportunity__r.RecordType.DeveloperName.equalsIgnoreCase('ECSS_SecondaryMarket') )
                {
                    
                    relatedsObjectId =documentRecord[0].Opportunity__c;
                    relatedAccountId = documentRecord[0].Opportunity__r.AccountId; 
 					relatedSignDocument = [ SELECT Id FROM Document__c 
                                            WHERE Opportunity__c =:documentRecord[0].Opportunity__c 
                                                AND DocumentType__c =: likedSignedString];
                   
                }// SSC-125 changes by BASHIM: end 
                else{
                    relatedsObjectId =documentRecord[0].Account__c; relatedAccountId = documentRecord[0].Account__c;
                    if(documentRecord[0].Case__c !=null){
                        relatedSignDocument = [select id from Document__C where Account__c = :documentRecord[0].Account__c and  DocumentType__c = :likedSignedString and Case__c = :documentRecord[0].Case__c ];
                        List<Case> caseList=[select Email__c from Case Where ID = :documentRecord[0].Case__c];
                        if(caseList!=null && !caseList.isEmpty()){
                            recipitEmail=caseList.get(0).Email__c;
                        }
                    }else{ relatedSignDocument = [select id from Document__C where Account__c = :documentRecord[0].Account__c and  DocumentType__c = :likedSignedString ];
                    }
                }
                if(relatedSignDocument.isEmpty()){
                   return 'Unable to find signed placeholder.';
                }
                
                /*if(isResale && oppComplianceStatus != 'Cleared'){
                    return System.Label.ResaleComplianceErrorMessage;
                }*/
               
                Account relatedAccount = [select id,isPersonAccount,ResidentStatus__pc, FirstName,LastName, PersonEmail,(select id,FirstName,LastName, Email from Contacts where PrimaryContact__c =true) from account where id = :relatedAccountId limit 1];
                if(documentRecord[0].Identityverification__c ){
                    Document__c doc = new Document__c(Id =documentRecord[0].id, DocuSignedDateTime__c=system.now().addSeconds(120));
                    update doc;
                    Double netAmount = UtilitiesWithoutSharing.getTotalNetAmounForDigitalSPA(documentRecord[0]);
                    if( netAmount > double.valueOf(Label.HalfBillion)){
                        return Label.HalfBillionErrorMessage; 
                    }
                }
                if(isResale){
                    if(documentRecord[0].DocumentType__c == 'Listing MOU'){
                        return  DocusignForMOUListing.sendForESignResale(documentRecord[0].Id,  relatedSignDocument[0].Id);
                    }else{
                        return sendForESignResale(documentRecord[0].Id, documentRecord[0].Opportunity__c, relatedSignDocument[0].Id);
                    }
                }else if(useDocuSignUtilityWrapper){
                    return sendForESignNew(recordId, relatedsObjectId, relatedAccountId, relatedSignDocument[0].Id);
                }else{
                    DocusignQESHelperNew.sendForQESSignatureFuture(recordId,relatedsObjectId,relatedAccountId,relatedSignDocument[0].Id,recipitEmail);
                }
                return Constants.SUCCESS_MESSAGE;   
                /*if(documentRecord[0].Identityverification__c){
                    return 'QES Success';              
                }else{
                    return Constants.SUCCESS_MESSAGE;
                }*/
            }else if(documentToContentVersionID.isEmpty()){
                return 'Please upload Document';
            }else if(documentRecord.isEmpty()){ return 'Unable to find record';
            }
            
        }catch(Exception e){
            return e.getMessage();
        } 
        
        return null;
    }
    
    @TestVisible private static String sendForESignNew(Id docRecordId, Id relatedsObjectId, Id relatedAccountId, Id relatedSignDocumentId) {
        DocuSignMapper.RecipientTypeSequence = new List<String>{'BUYER'};
        List<DocuSignWrapper.Signer> signers = new  List<DocuSignWrapper.Signer>{
            new DocuSignWrapper.Signer(relatedAccountId, relatedsObjectId, 'Buyer')
        };
        if(!signers.isEmpty()){
            return sendUsingWrapper(docRecordId, signers, relatedSignDocumentId);
        }else{
            
        }
        return Constants.SUCCESS_MESSAGE;
    }

    @TestVisible private static String sendForESignResale(Id docRecordId, Id opportunityId, Id relatedSignDocumentId) {
        DocuSignMapper.RecipientTypeSequence = new List<String>{'BUYER', 'SELLER'};
        // list signers
        List<DocuSignWrapper.Signer> signers = new  List<DocuSignWrapper.Signer>();
        for(Opportunity opp: [SELECT Id, AccountId, Seller__c, SalesOrder__c FROM Opportunity WHERE Id =: opportunityId LIMIT 1]){
            if(opp.AccountId != null){
                signers.add(new DocuSignWrapper.Signer(opp.AccountId, opp.Id, 'Buyer'));
            }
            if(opp.Seller__c != null){
                signers.add(new DocuSignWrapper.Signer(opp.Seller__c, opp.SalesOrder__c, 'Seller'));
            }
        }
        
        if(!signers.isEmpty()){
            return sendUsingWrapper(docRecordId, signers, relatedSignDocumentId);
        }else{

        }
        return Constants.SUCCESS_MESSAGE;
    }
    
    private static String sendUsingWrapper(Id docRecordId, List<DocuSignWrapper.Signer> signers, Id relatedSignDocumentId) {
        if(!signers.isEmpty()){
            DocuSignWrapper.EnvelopeWrapper envelopeWrapper = DocuSignMapper.createEnvelopeWrapper(docRecordId, signers);
            if(envelopeWrapper != null){
                dfsle.Envelope myEnvelope = DocuSignUtility.sendQESSignature(envelopeWrapper);
                if(myEnvelope != null){
                    myEnvelope = test.isRunningTest()?null: dfsle.EnvelopeService.sendEnvelope( myEnvelope,true);
                    String DocuSignID = test.isRunningTest()?'Test':String.valueOf(myEnvelope.docuSignId);

                    update new List<Document__c>{ 
                                new Document__c( 
                                    Id = relatedSignDocumentId, 
                                    DocuSignEnvelopeID__c = DocuSignID ), 
                                new Document__c( 
                                    Id = docRecordId, 
                                    SendForESign__c = false ) 
                            };
                }
            }else{

            }
        }else{

        }
        return Constants.SUCCESS_MESSAGE;
    }
    
    public static dfsle.Tab createEnvTab(string anchorString ) {
        
        dfsle.Tab envTab;
        dfsle.Tab.Anchor anchor = new dfsle.Tab.Anchor(
            anchorString, // Anchor string
            true, // Do not allow white space in anchor string
            false, // Anchor string is not case sensitive
            'right', // Horizontal alignment in relation to the anchor text
            true, // Ignore if the anchor text is not present in the document
            true, // Must match the value of the anchor string in its entirety
            'pixels', // Unit of the x and y offset properties
            -60, // X offset
            15);
        
        if(anchorString.contains('SignatureHolder')){
            envTab = new dfsle.SignHereTab().withAnchor(anchor);
        }else if(anchorString.contains('DateHolder')){
            envTab = new dfsle.DateSignedTab().withAnchor(anchor);
        }else if(anchorString.contains('InitialsHolder')){
            envTab = new dfsle.InitialHereTab().withAnchor(anchor);
        }else if(anchorString.contains('NameHolder')){
            envTab = new dfsle.FullNameTab().withAnchor(anchor);
        }
        
        return envTab;
        
    }

    
    @AuraEnabled(cacheable=false)
    public static String checkSignatureType(String recordId){
        String Message = '';
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        Boolean EnableRestrictEmailUpdate = Boolean.valueOf(label.EnableRestrictEmailUpdate);
        List<String> FasttrackMandateAccessProfile = label.FasttrackMandateAccessProfile.split(',');
        list<Document__c> documentRecord = [select id,Identityverification__c,DocumentType__c,SalesOrder__r.Account__c,Opportunity__r.AccountId,SalesOrder__r.Account__r.ResidentStatus__pc,SalesOrder__r.SignatureType__c,SalesOrder__r.Unit__r.Project__r.DigitalSignatureApplied__c,SalesOrder__r.Account__r.VisaType__c, Case__c, Account__c, Account__r.KYC_Validity_Status__c from Document__c where id= :recordId limit 1 ];
        if(documentRecord[0].DocumentType__c == 'KYC Form' && documentRecord[0].Account__c != NULL && FasttrackMandateAccessProfile.contains(profileName)) {
            Account acc = [SELECT Id, (SELECT Id FROM Exception_Requests__r WHERE Request_Type__c = 'Skip Fasttrack Signup' AND Request_Status__c = 'Approved' AND Request_End_Date__c >= TODAY), (SELECT Id FROM Communication_Preferences__r WHERE Source_Type__c ='Sales Manager' AND Category__c = 'FastTrack' AND Status__c = 'Fasttrack Completed' ORDER BY CreatedDate LIMIT 1) FROM Account WHERE Id =:documentRecord[0].Account__c LIMIT 1];
            
            if(acc.Exception_Requests__r.isEmpty() && (acc.Communication_Preferences__r.isEmpty() || documentRecord[0].Account__r.KYC_Validity_Status__c != 'Valid')) {
                return 'Send Fasttrack Link';
            } 
        }
        
        if(documentRecord.size() >0){
            DocumentPlaceholder__mdt mdt =[Select ID,Identityverification__c FROM DocumentPlaceholder__mdt where DocumentType__c =:documentRecord[0].DocumentType__c LIMIT 1];
            
                if(documentRecord[0].SalesOrder__r.Account__r.ResidentStatus__pc =='Non-Resident' && mdt.Identityverification__c == true && documentRecord[0].SalesOrder__r.Unit__r.Project__r.DigitalSignatureApplied__c ==true){
                    Message = 'Digital';
                }else if(documentRecord[0].SalesOrder__r.Account__r.ResidentStatus__pc =='Resident' && mdt.Identityverification__c == true && documentRecord[0].SalesOrder__r.Unit__r.Project__r.DigitalSignatureApplied__c ==true){
                    Message = 'SelectDigitalORUAE';
                }else if(documentRecord[0].DocumentType__c =='Parking Addendum'|| documentRecord[0].DocumentType__c =='Signed Parking Addendum' || documentRecord[0].DocumentType__c =='Parking ADM Registration'){
                    Message = 'Parking';
                }
            
        }
        return Message;
    }

     @AuraEnabled(cacheable=false)
     public static void sendFasttrackLink(String recordId) {
        try{
            List<Document__c> documentRecord = [SELECT Id, Account__c, DocumentType__c FROM Document__c WHERE Id =:recordId];
            List<Communication_Preference__c> communicationPreferenceList = [SELECT Id, Active__c FROM Communication_Preference__c WHERE Account__c =:documentRecord[0].Account__c AND Source_Type__c = 'Sales Manager'];
            
            for(Communication_Preference__c cp : communicationPreferenceList) {
                cp.Active__c = FALSE;
            }

            if(!communicationPreferenceList.isEmpty()) {
                update communicationPreferenceList;
            }

            SendFasttrackWhatsaAppLink.FlowInputs flowInput = new SendFasttrackWhatsaAppLink.FlowInputs();
            flowInput.accountId = documentRecord[0].Account__c;
            flowInput.category = 'FastTrack';
            flowInput.sourceType = 'Sales Manager';
            flowInput.status = 'Link Sent';
            flowInput.project = '';
            flowInput.salesOrderId = '';

            SendFasttrackWhatsaAppLink.createDigitalExpRecord(new List<SendFasttrackWhatsaAppLink.FlowInputs>{flowInput});
        } catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
     }
}