public class DocusignQESHelperNew 
{
    public static final String UAEPASSSIGNROLE = Label.DOCUSIGN_UAEPASSSIGNROLE;
    public static final String IDNOWSIGNROLE = Label.DOCUSIGN_IDNOWSIGNROLE;
    public static final String ALDARAPPROVERROLE = Label.DOCUSIGN_ALDARAPPROVERROLE;
    public static final String ALDARUAEPASSROLE = Label.DOCUSIGN_ALDARUAEPASSROLE;
    public static Integer idNowSequence = Integer.valueOf(Label.DOCUSIGN_idNowSequence) ;
    public static Integer uaePassSequence =  Integer.valueOf(Label.DOCUSIGN_uaePassSequence) ;
    public static Integer aldarApproverSequence =  Integer.valueOf(Label.DOCUSIGN_aldarApproverSequence) ;
    public static Integer aldarSignSequence =  Integer.valueOf(Label.DOCUSIGN_aldarSignSequence) ;
     
    @future(callout=true)
    public static void sendForQESSignatureFuture(String recordId,String relatedsObjectId,String relatedAccountId,String relatedSignDocumentId,String recipitEmailCase){
        try{
            //,SalesOrder__r.Unit__r.Project__r.DocuSigntemplateID__c
            List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
            list<Document__c> documentRecord = [select id,Identityverification__c,SalesOrder__r.UnitNumber__c,DocumentType__c,SalesOrder__c,ExpressionofInterest__c,SalesOrder__r.Account__c,ExpressionofInterest__r.Account__c,Account__c from Document__c where id= :recordId limit 1 ];
            map<id,id> documentToContentVersionID = new map<id,id>();
            for(ContentDocumentLink conDocLink : [select id,ContentDocumentId,ContentDocument.LatestPublishedVersionId,LinkedEntityId from ContentDocumentLink where LinkedEntityId = :recordId order by ContentDocument.CreatedDate DESC LIMIT 1 ]){
                documentToContentVersionID.put(conDocLink.LinkedEntityId,conDocLink.ContentDocument.LatestPublishedVersionId);
            }
            Map<Id,ContentVersion> contentVersionMap = new Map<Id,ContentVersion>([SELECT Id,FileType, Title, ContentDocumentId From ContentVersion where Id IN :documentToContentVersionID.values() order by createddate DESC ]);
            system.debug('contentVersionMap '+contentVersionMap);
            Account relatedAccount = [select id,isPersonAccount,AccountNumber__c,ResidentStatus__pc, FirstName,LastName, PersonEmail,(select id,FirstName,LastName, Email from Contacts where PrimaryContact__c =true) from account where id = :relatedAccountId limit 1];
            List<JointOwner__c> jointOwnerList = new List<JointOwner__c>();
            jointOwnerList = [SELECT Id,Account__c,Account__r.Name,Account__r.isPersonAccount,Account__r.ResidentStatus__pc,
                              FirstName__c,MiddleName__c,LastName__c,JointOwnerFullName__c,City__c,Salutation__c,
                              Nationality__c,Passport__c,Email__c,MobileNumber__c,Phone__c,Country__c,Suffix__c,
                              UAEID__c,SharePercentage__c  ,Account__r.AccountNumber__c
                              FROM JointOwner__c WHERE  SalesOrder__c = :relatedsObjectId ];
            
            //Esign Logic
            //Send all documents one by one
            // Create an empty envelope. with the DocID
            dfsle.Envelope myEnvelope;
            if(documentRecord[0].Identityverification__c){
                myEnvelope = prepareQESEnvelope(documentRecord[0],false,relatedsObjectId,relatedAccount,contentVersionMap.get(documentToContentVersionID.get(recordId)),jointOwnerList,false);
                //                    myEnvelope = DocusignQESHelperNew.prepareQESEnvelope(documentRecord[0],false,relatedsObjectId,relatedAccount, contentVersionMap.get(documentToContentVersionID.get(recordId)),jointOwnerList,false);
            }else{
                system.debug('+++++++++++NORMAL SIGNATURE+++++');
                //Create placeholders
                myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope( new dfsle.Entity(recordId));
                dfsle.Tab signatureTab;
                dfsle.Tab dateTab;
                dfsle.Tab initialHereTab;
                String recipitName;
                String recipitEmail;
                dfsle.Recipient myRecipient;
                
                signatureTab = DownloadSODocsController.createEnvTab( relatedsObjectId + 'SignatureHolder');
                
                dateTab = DownloadSODocsController.createEnvTab( relatedsObjectId + 'DateHolder');
                initialHereTab = DownloadSODocsController.createEnvTab( relatedsObjectId + 'InitialsHolder');
                // Add Recipient Salesorder's Account or Account's Primary Contact (must be present)
                
                recipitName = relatedAccount.isPersonAccount ? (relatedAccount.FirstName + ' '+ relatedAccount.LastName) : (relatedAccount.Contacts[0].FirstName + ' '+ relatedAccount.Contacts[0].LastName); // Recipient name
                    if(recipitEmailCase!=null && recipitEmailCase!=''){
                        recipitEmail=recipitEmailCase;
                    }else {
                        recipitEmail = relatedAccount.isPersonAccount ? (relatedAccount.PersonEmail ) : (relatedAccount.Contacts[0].Email ); // Recipient email
                            }
                
                myRecipient = dfsle.Recipient.fromSource(recipitName,recipitEmail,
                                                         null, // Optional phone number
                                                         null, // Role Name. Specify the exact role name from template
                                                         new dfsle.Entity(relatedAccount.isPersonAccount ? (relatedAccount.Id ) : (relatedAccount.Contacts[0].Id )))
                    .withTabs(new List<dfsle.Tab> {signatureTab,dateTab,initialHereTab}); // Source object for the Recipient
                
                // Add Recipient to the Envelope
                myEnvelope = myEnvelope.withRecipients(new List<dfsle.Recipient> { myRecipient });
                
                // Add Recipient to the Envelope
                myEnvelope = myEnvelope.withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(),new Set<id>{documentToContentVersionID.get(recordId)} ));
            }
            // Add document to the Envelope
            myEnvelope = test.isRunningTest() ? null: dfsle.EnvelopeService.sendEnvelope(myEnvelope,true);
            
            //Docusign Envelop ID
            string DocuSignID = test.isRunningTest()?'Test':String.valueOf(myEnvelope.docuSignId);
            Document__c relatedSignDocument = [select id from Document__c where Id = :relatedSignDocumentId];
            
            relatedSignDocument.DocuSignEnvelopeID__c=DocuSignID;
            documentRecord[0].SendForESign__c=false;
            if(documentRecord[0].Identityverification__c){
                if(relatedAccount.ResidentStatus__pc != null && relatedAccount.ResidentStatus__pc == 'Resident'){
                    documentRecord[0].EsignLocation__c='UAE Pass';
                }else{
                    documentRecord[0].EsignLocation__c='IDNow';
                }
                
                if(documentRecord[0].SalesOrder__c != null){
                    salesOrderList.add(new SalesOrder__c(Id=documentRecord[0].SalesOrder__c, SubStatus__c = 'Digital SPA Submitted for sign off'));
                } 
            }
            update new list<DOcument__c>{relatedSignDocument,documentRecord[0]};
                if(!salesOrderList.isEmpty()){
                    update salesOrderList;
                }    
        }catch(Exception e){
                    LoggerService.save(LoggerService.addApexLog(e,'DocusignQESHelperNew','sendForQESSignatureFuture',''));
                    String htmlEmailBody = Label.DocusignErrorEmailBody + ' <b> ' + e.getMessage() + ' </b> </br> ' ;
                    htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
                    String recipientString = Label.SysAdminEmailAddress;
                    List<String> recipientList = recipientString.split(';');
                    //SysAdminEmailAddress
                    //DocusignErrorEmailBody
                    Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'DocuSign Email Failure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
                } 
    }
    
    public static dfsle.Recipient prepareSignaturePlaceholder(String signerType, String roleStr,String signUniqueId,String dateUniqueId,String initialUniqueID,String recipientName,String recipientEmail,String relatedId,Integer routingOrder,Aldarsignatory__mdt aldarSign,dfsle.Tab myStampTab,String nameUniqueID){
        dfsle.Recipient myRecipient;
        system.debug('signUniqueId '+signUniqueId);
        system.debug('recipientName '+recipientName);
        system.debug('roleStr '+roleStr);
        system.debug('recipientEmail '+recipientEmail);
        system.debug('routingOrder '+routingOrder);
        system.debug('relatedId '+relatedId);
        dfsle.Tab signatureTab = DownloadSODocsController.createEnvTab( signUniqueId);
        dfsle.Tab dateTab = DownloadSODocsController.createEnvTab( dateUniqueId);
        dfsle.Tab initialHereTab = DownloadSODocsController.createEnvTab( initialUniqueID);
        dfsle.Tab nameTab = DownloadSODocsController.createEnvTab( nameUniqueID);

        if(signerType == 'Signer'){
        // Add Recipient Salesorder's Account or Account's Primary Contact (must be present)
                myRecipient = dfsle.Recipient.fromSource(recipientName,recipientEmail,
                                                         null, // Optional phone number
                                                         roleStr, // Role Name. Specify the exact role name from template
                                                         new dfsle.Entity(relatedId))
                    .withTabs(new List<dfsle.Tab> {signatureTab,dateTab,initialHereTab,myStampTab,nameTab}).withRoutingOrder(routingOrder); // Source object for the Recipient
        }else if(signerType == 'Approver'){
            dfsle.Tab myApproveTab = new dfsle.ApproveTab().withPosition(new dfsle.Tab.Position(
                1, // The document to use
                1, // Page number on the document
                210, // X position
                105, // Y position
                100, // 100 pixels wide
                null)); // Default height
            myRecipient = dfsle.Recipient.fromSource(recipientName,recipientEmail,
                                                     null, // Optional phone number
                                                     roleStr, // Role Name. Specify the exact role name from template
                                                     new dfsle.Entity(relatedId))
                .withTabs(new List<dfsle.Tab> {signatureTab,dateTab,initialHereTab,myApproveTab}).withRoutingOrder(routingOrder); // Source object for the Recipient

            /* 
                myRecipient = new dfsle.Recipient(
                    null, //Source Id
                    'Signer',//Type of recipient
                    null, //Sequence
                    routingOrder, //routing order
                    new dfsle.Recipient.Role(roleStr,null), //role -used to match role
                    //on template if using a template
                    null, //inPerson Recipient name
                    null, //inPerson Recipient Email
                    new dfsle.SigningGroup(Integer.valueOf(aldarSign.SigninggroupId__c) , aldarSign.Signinggroupname__c), //signing group
                    null, //phone
                    null,//no Authentication
                    null, //note
                    null, //EmailSettings
                    null, //host name This is the name of the host for InPerson
                    null, //host email email of host
                    true, //sign now
                    null, //source
                    false, //read only
                    false).withTabs(new List<dfsle.Tab> { myApproveTab}).withRoutingOrder(routingOrder); //required
*/
        
        }
        return myRecipient;
    }
    
    public static dfsle.Envelope prepareQESEnvelope(Document__c docRecord,Boolean qesEnabled,String relatedsObjectId,Account primaryRecipients, ContentVersion cv,List<JointOwner__c> jointOwnerList,boolean aldarSignarure){
        //Esign Logic
        //Send all documents one by one
        // Create an empty envelope. with the DocID
        dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope( new dfsle.Entity(docRecord.Id));
        //Create placeholders
        String recipitName;
        String recipitEmail;
//        dfsle.Recipient myRecipient;
        dfsle.UUID myTemplateId ;
        dfsle.Document myDocument;
        system.debug('relatedsObjectId '+relatedsObjectId);
        List<dfsle.Recipient> recipientList =  new List<dfsle.Recipient>();
        Organization org = Utilities.getOrganizationDetails();
        system.debug('-----SENDING');
        myTemplateId = dfsle.UUID.parse(Label.DocuSign_Template_Id);
     /*   String templateId = '';
        if(docRecord.SalesOrder__r.Unit__r.Project__r.DocuSigntemplateID__c != null){
            templateId = docRecord.SalesOrder__r.Unit__r.Project__r.DocuSigntemplateID__c ;
        }else{
            templateId = Label.DocuSign_Template_Id;
        }
     system.debug('++templateId '+templateId);
        myTemplateId = dfsle.UUID.parse(templateId);
*/
        myDocument = dfsle.Document.fromTemplate(
            myTemplateId, // templateId in dfsle.UUID format
            'Aldar'); // name of the template

        // Place holder for primary recipient
        String primaryRecipientRole = '';
        Integer routingOrder;
        if(primaryRecipients.ResidentStatus__pc != null && primaryRecipients.ResidentStatus__pc == 'Resident'){
            primaryRecipientRole += UAEPASSSIGNROLE + '1';
            //uaePassSequence = uaePassSequence + 1;
            system.debug('uaePassSequence '+uaePassSequence);
            routingOrder = uaePassSequence;
        }else{
            primaryRecipientRole += IDNOWSIGNROLE + '1';
           // idNowSequence = idNowSequence + 1; 
            system.debug('idNowSequence '+idNowSequence);
            routingOrder = idNowSequence;
        }
        String recipientName = primaryRecipients.isPersonAccount ? (primaryRecipients.FirstName + ' '+ primaryRecipients.LastName) : (primaryRecipients.Contacts[0].FirstName + ' '+ primaryRecipients.Contacts[0].LastName); // Recipient name
            if(org.IsSandbox && primaryRecipients.ResidentStatus__pc != null && primaryRecipients.ResidentStatus__pc == 'Non-Resident'){
                recipientName += ' X-MANUALTEST-HAPPYPATH';
            }
            String recipientEmail = primaryRecipients.isPersonAccount ? (primaryRecipients.PersonEmail ) : (primaryRecipients.Contacts[0].Email ); // Recipient email
        String primarySignHolder = primaryRecipients.isPersonAccount ? primaryRecipients.AccountNumber__c+'SignatureHolder' : primaryRecipients.AccountNumber__c+'OrgSignatureHolder'; 
        String primaryDateHolder = primaryRecipients.isPersonAccount ? primaryRecipients.AccountNumber__c+'DateHolder' : primaryRecipients.AccountNumber__c+'OrgDateHolder'; 
        String primaryInitialHolder = primaryRecipients.isPersonAccount ? primaryRecipients.AccountNumber__c+'InitialsHolder' : primaryRecipients.AccountNumber__c+'OrgInitialsHolder'; 
        String primaryNameHolder = primaryRecipients.isPersonAccount ? primaryRecipients.AccountNumber__c+'NameHolder' : primaryRecipients.AccountNumber__c+'OrgNameHolder'; 
        //--Stamp start
        dfsle.SignHereTab.Stamp myStamp = new dfsle.SignHereTab.Stamp('stamp',null,null,null,null,null,null,null);       
        dfsle.Tab myStampTab = new dfsle.SignHereTab().withStamp(myStamp)
            .withScale(1.5) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'AldarStampHolder', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'right', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0)); // Y offset
        
        //----Stamp end

        recipientList.add(prepareSignaturePlaceholder('Signer',primaryRecipientRole, primarySignHolder,primaryDateHolder,primaryInitialHolder,recipientName,recipientEmail,docRecord.Id,routingOrder,null,null,primaryNameHolder));
        routingOrder = routingOrder++;

        Integer signCount = 2;
        for(JointOwner__c jo : jointOwnerList){
            // Add Recipient Salesorder's Account or Account's Primary Contact (must be present)
            String joRole = '';
            Integer routingOrder2;
            if(jo.Account__r.ResidentStatus__pc != null && jo.Account__r.ResidentStatus__pc == 'Resident'){
                joRole += UAEPASSSIGNROLE + String.valueOf(signCount);
                system.debug('before uaePassSequence '+uaePassSequence);
                uaePassSequence = uaePassSequence + 1;
                system.debug('uaePassSequence '+uaePassSequence);
                routingOrder2 = uaePassSequence;
            }else{
                joRole += IDNOWSIGNROLE + String.valueOf(signCount);
                system.debug('before idNowSequence '+idNowSequence);
                idNowSequence = idNowSequence +  1;
                system.debug('idNowSequence '+idNowSequence);
                routingOrder2 = idNowSequence;
            }
            recipientName = jo.Account__r.Name;
           // recipientName  = (jo.FirstName__c == null ? '' : jo.FirstName__c )  + ' ' + (jo.MiddleName__c == null ? '': jo.MiddleName__c + ' ') + jo.LastName__c == null ? '':jo.LastName__c  ;// Recipient name
            if(org.IsSandbox && jo.Account__r.ResidentStatus__pc != null && jo.Account__r.ResidentStatus__pc == 'Non-Resident'){
                recipientName += ' X-MANUALTEST-HAPPYPATH';
            }
            recipientEmail = jo.Email__c ; // Recipient email org and 
            String joSignHolder = jo.Account__r.isPersonAccount ? jo.Account__r.AccountNumber__c+'SignatureHolder' : jo.Account__r.AccountNumber__c+'OrgSignatureHolder'; 
            String joDateHolder = jo.Account__r.isPersonAccount ? jo.Account__r.AccountNumber__c+'DateHolder' : jo.Account__r.AccountNumber__c+'OrgDateHolder'; 
            String joInitialHolder = jo.Account__r.isPersonAccount ? jo.Account__r.AccountNumber__c+'InitialsHolder' : jo.Account__r.AccountNumber__c+'OrgInitialsHolder'; 
            String joNameHolder = jo.Account__r.isPersonAccount ? jo.Account__r.AccountNumber__c+'NameHolder' : jo.Account__r.AccountNumber__c+'OrgNameHolder'; 

            recipientList.add(prepareSignaturePlaceholder('Signer',joRole,joSignHolder,joDateHolder,joInitialHolder,recipientName,recipientEmail,docRecord.Id,routingOrder2,null,null,joNameHolder));
            signCount++;
        }
        
        List<Aldarsignatory__mdt> aldarSign = [Select Id,email__c,Order__c,Type__c ,MasterLabel,DeveloperName,SigninggroupId__c,Signinggroupname__c FROM Aldarsignatory__mdt where active__c = true ORDER BY Order__c ];
        //ALDAR SIGN
        for(Aldarsignatory__mdt aSign : aldarSign){
            recipientName = aSign.MasterLabel;
            //Approver Signatory
            if(aSign.Type__c == 'Approver'){
                system.debug('----------- aldarApproverSequence '+aldarApproverSequence);
                recipientList.add(prepareSignaturePlaceholder('Approver',aSign.DeveloperName,aSign.DeveloperName,aSign.DeveloperName,aSign.DeveloperName,recipientName,aSign.email__c,docRecord.Id,aldarApproverSequence,aSign,null,recipientName+'NameHolder'));
            }else if(aSign.Type__c == 'Signatory'){
                recipientEmail = aSign.email__c ; // Recipient email

                recipientList.add(prepareSignaturePlaceholder('Signer',aSign.DeveloperName,'AldarSignatureHolder','AldarDateHolder','AldarInitialsHolder',recipientName,recipientEmail,docRecord.Id,aldarSignSequence,aSign,myStampTab,'AldarNameHolder'));
            }
            String joRole = 'AldarUAEPassSign';
            aldarApproverSequence = aldarApproverSequence + 1;

        }
        //ALDAR SIGN ENDS
        
        // Add Recipient to the Envelope
        myEnvelope = myEnvelope.withRecipients(recipientList);
        String sub = Label.DOCUSIGN_EmailSubject +' '+docRecord.SalesOrder__r.UnitNumber__c;
        String emailBody = '';
        emailBody += Label.DOCUSIGN_EmailBody;
        emailBody += '<a href="';
        
        if(primaryRecipients.ResidentStatus__pc != null && primaryRecipients.ResidentStatus__pc == 'Resident'){
            emailBody += Label.DOCUSIGN_UAEPassLink;
        }else{
            emailBody += Label.DOCUSIGN_IdNowLink;
        }
        emailBody += '" target="_blank"> click here</a>';
        emailBody += Label.DOCUSIGN_EmailBody2;   
        emailBody += Label.DOCUSIGN_EmailBody3;  
       /* emailBody += Label.DOCUSIGN_EmailBodyAR1;  
        emailBody += '<a href="';
        if(primaryRecipients.ResidentStatus__pc != null && primaryRecipients.ResidentStatus__pc == 'Resident'){
            emailBody += Label.DOCUSIGN_ARUAEPassLink;
        }else{
            emailBody += Label.DOCUSIGN_ARIdNowLink;
        }
        emailBody += '" target="_blank">'+Label.DOCUSIGN_ARClickHere +'</a>';
        emailBody += Label.DOCUSIGN_EmailBodyAR2;
    */
        myEnvelope = myEnvelope.withEmail(sub,emailBody);
        dfsle.Notifications notifyRecipients = new dfsle.Notifications(
            false, // Indicates that reminders are enabled
            0, // Number of days to wait before sending a reminder
            0, // Number of days between reminders
            true, // Whether or not the envelope expires and is voided
            730, // Number of days before the envelope expires
            10, // Number of days before expiration to remind the recipient
            false // Placeholder for deprecated field
        );
        myEnvelope = myEnvelope.withNotifications(notifyRecipients);

        //,emailBody
        //SalesOrder__r.UnitNumber__c ,
        // Add Recipient to the Envelope
        system.debug('--- cv '+cv.Id);
        ContentVersion cv1 = [SELECT Id,FileType, Title, ContentDocumentId From ContentVersion where Id =:cv.Id order by createddate DESC ];
        system.debug('------ cv '+cv1);

        myDocument.withReplacement(dfsle.Document.fromFile(cv1));
        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        //myEnvelope = myEnvelope.withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(),new Set<id>{documentToContentVersionID.get(recordId)} ));
        return myEnvelope;
    }


}