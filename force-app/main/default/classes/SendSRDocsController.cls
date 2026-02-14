/*
* Purpose: Send Document for eSignature via DocuSign
*/
public with sharing class SendSRDocsController {

    /*
    * Logic: Check Document is eligible to send for eSign or not
    *           If it is eligible, determine if it is necessary to send for Authorised Signatory signatures and 
    *           returns a list of Authorised Signatory names.
    */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getRecordDetails(String recordId) {
        Map<String, Object> returnMap = new Map<String, Object>();
        HexaBPM__SR_Doc__c documentRecord = [SELECT Id, Name, DocumentMasterCode__c, HexaBPM__Service_Request__r.RecordType.Name, 
                                                HexaBPM__SR_Template_Doc__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c 
                                                FROM HexaBPM__SR_Doc__c WHERE Id =: recordId LIMIT 1];
        
        if (documentRecord.HexaBPM__SR_Template_Doc__r.ESignGroup__c != null && (documentRecord.HexaBPM__SR_Template_Doc__r.ESignGroup__c.contains(Constants.CUSTOMER_ESIGN) || documentRecord.HexaBPM__SR_Template_Doc__r.ESignGroup__c.contains(Constants.BUYER_ESIGN))){
            returnMap.put(Constants.SUCCESS_RETURN_MESSAGE, Constants.SUCCESS_RETURN_MESSAGE);
        }
        if (documentRecord.HexaBPM__SR_Template_Doc__r.ESignGroup__c != null && documentRecord.HexaBPM__SR_Template_Doc__r.ESignGroup__c.contains(Constants.AUTHORISED_SIGNATORY_ESIGN)){
            
            List<InternalSignatories__mdt> signList = new List<InternalSignatories__mdt>();
            //Below NOC_BROKER_LETTER check is added by Tharun BPE-87
            if(documentRecord.DocumentMasterCode__c == Ald_Constants.NOC_BROKER_LETTER){
                signList = [SELECT Id, FullName__c, EmailAddress__c, Type__c, DeveloperName  FROM InternalSignatories__mdt WHERE DeveloperName = :Ald_Constants.NOC_BROKER_LETTER];    
            }else{
                signList = [SELECT Id, FullName__c, EmailAddress__c, Type__c FROM InternalSignatories__mdt WHERE Type__c =: documentRecord.HexaBPM__Service_Request__r.RecordType.Name];
            }
            //Above NOC_BROKER_LETTER is added by Tharun BPE-87
            if (!signList.isEmpty()) {
                returnMap.put(Constants.SUCCESS_RETURN_MESSAGE, signList);
            } else {
                returnMap.put(Constants.ERROR_RETURN_MESSAGE, 'This document does not have any Authorised Signatory.');
            }
        } else {
            returnMap.put(Constants.ERROR_RETURN_MESSAGE, 'This document cannot be sent for eSign');
        }
        System.debug('returnMap -->>'+returnMap);
        return returnMap;
    }

    /*
    * Logic: Check to see that the appropriate document placeholder is available, as well as eligibility, before sending for eSign.
    */
    @AuraEnabled(cacheable=false)
    public static String sendForESign(String recordId, String authorisedSignatory) {
        HexaBPM__SR_Doc__c documentRecord = [SELECT Id, Name, DocumentMasterCode__c, HexaBPM__Service_Request__c, HexaBPM__SR_Template_Doc__r.QualifiedSignature__c FROM HexaBPM__SR_Doc__c WHERE Id =: recordId LIMIT 1];

        if(documentRecord.HexaBPM__SR_Template_Doc__r.QualifiedSignature__c) {
            return sendDocumentForESignQES(recordId, authorisedSignatory, false);
        } else {
            return sendDocumentForESign(recordId, authorisedSignatory, false);
        }
    }
    
    public static String sendDocumentForESign(String recordId, String authorisedSignatory, Boolean isReturnDocuSignId) {
        try {
            System.debug('recordId>>> ' + recordId);
            List<HexaBPM__SR_Doc__c> docRecords = [SELECT Id, Name, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.RecordTypeId, 
                                                    HexaBPM__Service_Request__r.RecordType.Name, DocumentMasterCode__c, 
                                                    HexaBPM__SR_Template_Doc__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, 
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__c,HexaBPM__Service_Request__r.SalesOrder__c,
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.Name, 
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail,
                                                    HexaBPM__Service_Request__r.Unit__r.Project__r.Development_Manager_Email__c, 
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.Email__c, 
                                                    HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__Service_Request__r.BuyerName__r.Name, 
                                                    HexaBPM__Service_Request__r.BuyerName__r.PersonEmail,
                                                    HexaBPM__Service_Request__r.HandoverDetail__c, 
                                                    HexaBPM__Service_Request__r.BuyerName__r.Email__c, (SELECT Id, ContentDocumentId, 
                                                    ContentDocument.LatestPublishedVersionId, LinkedEntityId FROM ContentDocumentLinks ORDER BY SystemModstamp DESC)
                                                    FROM HexaBPM__SR_Doc__c WHERE Id =: recordId LIMIT 1];
            
            if (!docRecords.isEmpty()) {
                HexaBPM__SR_Doc__c srDoc = docRecords[0];
                String recordTypeName = [SELECT Name, RecordType.DeveloperName FROM HexaBPM__Service_Request__c WHERE Id =:srDoc.HexaBPM__Service_Request__c LIMIT 1].RecordType.DeveloperName;

                if (srDoc.HexaBPM__SR_Template_Doc__r.ESignGroup__c == null /*&& recordTypeName != Constants.DEFAULT_AND_TERMINATION_DEV_RT && srDoc.Name != ALD_Constants.DOCUMENT_D_AND_T_MEMO*/) {
                    return 'Please select Esign Group to send this document for signature.';
                }

                List<String> eSignGroupList = String.isNotBlank(srDoc.HexaBPM__SR_Template_Doc__r.ESignGroup__c) ? srDoc.HexaBPM__SR_Template_Doc__r.ESignGroup__c.split(';') : new List<String>();

                List<HexaBPM__SR_Doc__c> relatedSignDocument = new List<HexaBPM__SR_Doc__c>();
                if (srDoc.DocumentMasterCode__c.containsIgnoreCase(Constants.DOCUMENT_TYPE_PREFIX_SIGNED)) {
                    String likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_COUNTER + '_' + srDoc.DocumentMasterCode__c;                
                              string LikedAldarsignedstring=Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA;
                   relatedSignDocument = [SELECT Id FROM HexaBPM__SR_Doc__c WHERE (DocumentMasterCode__c =: likedSignedString OR DocumentMasterCode__c =: LikedAldarsignedstring)
                                                AND HexaBPM__Service_Request__c =: srDoc.HexaBPM__Service_Request__c];
                    if (relatedSignDocument.isEmpty()) {
                        return 'Unable to find counter signed placeholder.';
                    }
                } else {
                    String likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '_' + srDoc.DocumentMasterCode__c;                
                    relatedSignDocument = [SELECT Id FROM HexaBPM__SR_Doc__c WHERE DocumentMasterCode__c =: likedSignedString 
                                                AND HexaBPM__Service_Request__c =: srDoc.HexaBPM__Service_Request__c];
                    if (relatedSignDocument.isEmpty()) {
                        return 'Unable to find signed placeholder.';
                    }
                }

                /*if(srDoc.Name == Constants.DOCUMENT_UNIFIED_HANDOVER_DOCUMENTS && srDoc.HexaBPM__Service_Request__r.HandoverDetail__c != NULL) {
                    HandoverDetails__c handoverDetails = new HandoverDetails__c();
                    handoverDetails.Id = srDoc.HexaBPM__Service_Request__r.HandoverDetail__c;
                    handoverDetails.Docusign_Sent_Date__c = System.today();
                    update handoverDetails;
                }*/
                
                return DocuSignHelper.sendSRDocForESign(srDoc, relatedSignDocument, eSignGroupList, authorisedSignatory);//isReturnDocuSignId
                
            } else {
                return 'Unable to find record';
            }
        } catch(Exception e) {
            return e.getMessage();
        }
    }

    public static final String UAEPASSSIGNROLE = Label.DOCUSIGN_UAEPASSSIGNROLE;
    public static final String IDNOWSIGNROLE = Label.DOCUSIGN_IDNOWSIGNROLE;
    public static final String ALDARAPPROVERROLE = Label.DOCUSIGN_ALDARAPPROVERROLE;
    public static final String ALDARUAEPASSROLE = Label.DOCUSIGN_ALDARUAEPASSROLE;
    public static Integer idNowSequence = Integer.valueOf(Label.DOCUSIGN_idNowSequence);
    public static Integer uaePassSequence =  Integer.valueOf(Label.DOCUSIGN_uaePassSequence);
    public static Integer aldarApproverSequence =  Integer.valueOf(Label.DOCUSIGN_aldarApproverSequence);
    public static Integer aldarSignSequence =  Integer.valueOf(Label.DOCUSIGN_aldarSignSequence);

    public static String sendDocumentForESignQES(String recordId, String authorisedSignatory, Boolean isReturnDocuSignId) {
        try {
            List<String> eSignGroup = new List<String>();
            List<HexaBPM__SR_Doc__c> docRecords = [SELECT Id, Name, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.RecordTypeId, HexaBPM__Service_Request__r.Unit__c,HexaBPM__Service_Request__r.Unit__r.Project__r.MCD_Link__c, HexaBPM__Service_Request__r.Unit__r.name, HexaBPM__Service_Request__r.SalesOrder__c,
                                                    HexaBPM__Service_Request__r.RecordType.Name, DocumentMasterCode__c, HexaBPM__Service_Request__r.HandoverDetail__c,
                                                    HexaBPM__SR_Template_Doc__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, 
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__c, HexaBPM__Service_Request__r.SRType__c,
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.Name, 
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail, 
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.Email__c,
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc,
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.CustomerType__c, 
                                                    HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__Service_Request__r.BuyerName__r.Name, 
                                                    HexaBPM__Service_Request__r.BuyerName__r.PersonEmail,
                                                    HexaBPM__Service_Request__r.BuyerName__r.ResidentStatus__pc,
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.isPersonAccount,
                                                    HexaBPM__Service_Request__r.BuyerName__r.isPersonAccount,
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.AccountNumber__c,
                                                    HexaBPM__Service_Request__r.BuyerName__r.AccountNumber__c,
                                                    HexaBPM__Service_Request__r.BuyerName__r.CustomerType__c, 
                                                    HexaBPM__Service_Request__r.BuyerName__r.Email__c,
                                                    HexaBPM__Service_Request__r.SalesOrder__r.Account__c, HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Name, 
                                                    HexaBPM__Service_Request__r.SalesOrder__r.Account__r.isPersonAccount,
                                                    HexaBPM__Service_Request__r.SalesOrder__r.Account__r.ResidentStatus__pc,
                                                    HexaBPM__Service_Request__r.SalesOrder__r.Account__r.AccountNumber__c,
                                                    HexaBPM__Service_Request__r.SalesOrder__r.Account__r.CustomerType__c,
                                                    HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Email__c,
                                                    HexaBPM__Service_Request__r.SalesOrder__r.Account__r.PersonEmail,
                                                    HexaBPM__Document_Master__r.TemplateID__c, HexaBPM__Service_Request__r.HOKAR__r.Email, 
                                                    HexaBPM__Service_Request__r.HOKAR__r.Name, (SELECT Id, ContentDocumentId, 
                                                    ContentDocument.LatestPublishedVersionId, LinkedEntityId FROM ContentDocumentLinks ORDER BY SystemModstamp DESC)
                                                    FROM HexaBPM__SR_Doc__c WHERE Id =: recordId LIMIT 1];

            List<JointOwner__c> sellerJointOwnerList = new List<JointOwner__c>();

            if(docRecords[0].HexaBPM__Service_Request__r.SalesOrder__c != null) {
                sellerJointOwnerList = [SELECT Id, Account__c, Email__c, RelationshipType__c, Account__r.Name, Account__r.isPersonAccount, Account__r.PersonEmail, Account__r.Email__c,
                                        Account__r.ResidentStatus__pc, Account__r.AccountNumber__c, Account__r.CustomerType__c, SalesOrder__c, SalesOrder__r.Account__c
                                        FROM JointOwner__c WHERE SalesOrder__c = :docRecords[0].HexaBPM__Service_Request__r.SalesOrder__c];
            }

            //List<InternalSignatories__mdt> listInternalSignatories = [SELECT Id, MasterLabel, EmailAddress__c, FullName__c, OrderNo__c, Type__c from InternalSignatories__mdt WHERE Type__c ='Property Transfer'];
            
            List<AgencyTeam__c> buyerJointOwnerList = [SELECT Id, Account__c, Account__r.Name, Account__r.isPersonAccount, Account__r.ResidentStatus__pc, Account__r.Email__c, Account__r.PersonEmail,
                                                        Name, EmailAddress__c, MobileNumber__c, Country__c, Type__c, UniqueKey__c,
                                                        ShareHoldingPercentage__c, Account__r.AccountNumber__c, Account__r.CustomerType__c
                                                        FROM AgencyTeam__c WHERE ServiceRequest__c = :docRecords[0].HexaBPM__Service_Request__c];
            
            if(String.isNotBlank(docRecords[0].HexaBPM__SR_Template_Doc__r.ESignGroup__c)){
                eSignGroup = docRecords[0].HexaBPM__SR_Template_Doc__r.ESignGroup__c.split(';');
            }

            if (!docRecords.isEmpty()) {
                HexaBPM__SR_Doc__c srDoc = docRecords[0];
                String recordTypeName = [SELECT Name, RecordType.DeveloperName FROM HexaBPM__Service_Request__c WHERE Id =:srDoc.HexaBPM__Service_Request__c LIMIT 1].RecordType.DeveloperName;
                Integer signCount = 1;
                //get latest content version Id
                Id documentToContentVersionId = srDoc.ContentDocumentLinks[0].ContentDocument.LatestPublishedVersionId;
                //get content version record for docusign wrapper
                contentVersion contentVersionRecord = [SELECT Id,FileType, Title, ContentDocumentId FROM ContentVersion WHERE Id =:documentToContentVersionId LIMIT 1];
                Integer routingOrderResident = uaePassSequence;
                Integer routingOrderNonResident = idNowSequence;
                List<DocuSignWrapper.RecipientWrapper> recipientList = new List<DocuSignWrapper.RecipientWrapper>();
                List<DocuSignWrapper.AldarSignatories> aldarSignatoryList = new List<DocuSignWrapper.AldarSignatories>();
                List<dfsle.Recipient> recipientList2 =  new List<dfsle.Recipient>();

                //add Seller as recipient
                if(eSignGroup.contains(Constants.CUSTOMER_ESIGN) && srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__c != null && recordTypeName == Constants.HANDOVER_RT) {
                    Account acc = new Account();
                    acc.Name = srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Name;
                    acc.Email__c = srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Email__c;
                    acc.PersonEmail = srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.PersonEmail;
                    acc.ResidentStatus__pc = srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.ResidentStatus__pc;
                    acc.CustomerType__c = srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.CustomerType__c;

                    String role = (srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.ResidentStatus__pc == 'Resident' ? UAEPASSSIGNROLE : IDNOWSIGNROLE) + String.valueOf(signCount);

                    DocuSignWrapper.RecipientWrapper recipient = recipientFieldMapping(acc, srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.isPersonAccount, srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.AccountNumber__c, role, 'Seller', 'Signer');
                    recipient.routingOrder = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc == 'Resident' ? routingOrderResident : routingOrderNonResident;
                    recipientList.add(recipient);

                    if(srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.ResidentStatus__pc == 'Resident'){
                        routingOrderResident = routingOrderResident + 1;
                    } else{
                        routingOrderNonResident = routingOrderNonResident + 1;
                    }

                    signCount++;
                } else if(eSignGroup.contains(Constants.CUSTOMER_ESIGN) && srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__c != null) {
                    //add Customer as recipient
                    Account acc = new Account();
                    acc.Name = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.Name;
                    acc.Email__c = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.Email__c;
                    acc.PersonEmail = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail;
                    acc.ResidentStatus__pc = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc;
                    acc.CustomerType__c = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.CustomerType__c;

                    String role = (srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc == 'Resident' ? UAEPASSSIGNROLE : IDNOWSIGNROLE) + String.valueOf(signCount);

                    DocuSignWrapper.RecipientWrapper recipient = recipientFieldMapping(acc, srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.isPersonAccount, srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.AccountNumber__c, role, 'Seller', 'Signer');
                    recipient.routingOrder = srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc == 'Resident' ? routingOrderResident : routingOrderNonResident;
                    recipientList.add(recipient);

                    if(srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc == 'Resident'){
                        routingOrderResident = routingOrderResident + 1;
                    } else{
                        routingOrderNonResident = routingOrderNonResident + 1;
                    }

                    signCount++;
                }

                //add Buyer as recipient 
                if(eSignGroup.contains(Constants.BUYER_ESIGN) && srDoc.HexaBPM__Service_Request__r.BuyerName__c != null && recordTypeName != Constants.HANDOVER_RT) {
                    Account acc = new Account();
                    acc.Name = srDoc.HexaBPM__Service_Request__r.BuyerName__r.Name;
                    acc.Email__c = srDoc.HexaBPM__Service_Request__r.BuyerName__r.Email__c;
                    acc.PersonEmail = srDoc.HexaBPM__Service_Request__r.BuyerName__r.PersonEmail;
                    acc.ResidentStatus__pc = srDoc.HexaBPM__Service_Request__r.BuyerName__r.ResidentStatus__pc;
                    acc.CustomerType__c = srDoc.HexaBPM__Service_Request__r.BuyerName__r.CustomerType__c;
                    String role = (srDoc.HexaBPM__Service_Request__r.BuyerName__r.ResidentStatus__pc == 'Resident' ? UAEPASSSIGNROLE : IDNOWSIGNROLE) + String.valueOf(signCount);

                    DocuSignWrapper.RecipientWrapper recipient = recipientFieldMapping(acc, srDoc.HexaBPM__Service_Request__r.BuyerName__r.isPersonAccount, srDoc.HexaBPM__Service_Request__r.BuyerName__r.AccountNumber__c, role, 'Buyer', 'Signer');
                    recipient.routingOrder = srDoc.HexaBPM__Service_Request__r.BuyerName__r.ResidentStatus__pc == 'Resident' ? routingOrderResident : routingOrderNonResident;
                    recipientList.add(recipient);

                    if(srDoc.HexaBPM__Service_Request__r.BuyerName__r.ResidentStatus__pc == 'Resident'){
                        routingOrderResident = routingOrderResident + 1;
                    } else{
                        routingOrderNonResident = routingOrderNonResident + 1;
                    }

                    signCount++;
                }

                if(eSignGroup.contains(Constants.CUSTOMER_WITH_JOINT_OWNER_ESIGN)) {
                    for(JointOwner__c jo : sellerJointOwnerList) {
                        Account acc = new Account();
                        acc.Name = jo.Account__r.Name;
                        acc.Email__c = jo.Account__r.Email__c;
                        acc.PersonEmail = jo.Account__r.PersonEmail;
                        acc.ResidentStatus__pc = jo.Account__r.ResidentStatus__pc;
                        acc.CustomerType__c = jo.Account__r.CustomerType__c;
                        
                        DocuSignWrapper.RecipientWrapper recipient = recipientFieldMapping(acc, jo.Account__r.isPersonAccount, jo.Account__r.AccountNumber__c, '', 'JointOwner', 'Signer');

                        String joRole = '';

                        if(jo.Account__r.ResidentStatus__pc != null && jo.Account__r.ResidentStatus__pc == 'Resident'){
                            joRole += UAEPASSSIGNROLE + String.valueOf(signCount);
                            recipient.routingOrder = routingOrderResident;
                            routingOrderResident = routingOrderResident + 1;
                        } else {
                            joRole += IDNOWSIGNROLE + String.valueOf(signCount);
                            recipient.routingOrder = routingOrderNonResident;
                            routingOrderNonResident = routingOrderNonResident +  1;
                        }

                        recipient.role = joRole;
                        recipientList.add(recipient);

                        signCount++;
                    }
                }
                
                if(eSignGroup.contains(Constants.BUYER_WITH_JOINT_OWNER_ESIGN) && recordTypeName == Constants.HANDOVER_RT) {
                    //joint owners
                    for(JointOwner__c jo : sellerJointOwnerList) {
                        Account acc = new Account();
                        acc.Name = jo.Account__r.Name;
                        acc.Email__c = jo.Account__r.Email__c;
                        acc.PersonEmail = jo.Account__r.PersonEmail;
                        acc.ResidentStatus__pc = jo.Account__r.ResidentStatus__pc;
                        acc.CustomerType__c = jo.Account__r.CustomerType__c;
                        
                        DocuSignWrapper.RecipientWrapper recipient = recipientFieldMapping(acc, jo.Account__r.isPersonAccount, jo.Account__r.AccountNumber__c, '', 'JointOwner', 'Signer');

                        String joRole = '';

                        if(jo.Account__r.ResidentStatus__pc != null && jo.Account__r.ResidentStatus__pc == 'Resident'){
                            joRole += UAEPASSSIGNROLE + String.valueOf(signCount);
                            recipient.routingOrder = routingOrderResident;
                            routingOrderResident = routingOrderResident + 1;
                        } else {
                            joRole += IDNOWSIGNROLE + String.valueOf(signCount);
                            recipient.routingOrder = routingOrderNonResident;
                            routingOrderNonResident = routingOrderNonResident +  1;
                        }

                        recipient.role = joRole;
                        recipientList.add(recipient);
                        System.debug('recipient==> ' + recipient);
                        signCount++;
                    }
                } else if(eSignGroup.contains(Constants.BUYER_WITH_JOINT_OWNER_ESIGN)) {
                    for(AgencyTeam__c jo : buyerJointOwnerList) {
                        Account acc = new Account();
                        acc.Name = jo.Account__r.Name;
                        acc.Email__c = jo.Account__r.Email__c;
                        acc.PersonEmail = jo.Account__r.PersonEmail;
                        acc.ResidentStatus__pc = jo.Account__r.ResidentStatus__pc;
                        acc.CustomerType__c = jo.Account__r.CustomerType__c;

                        DocuSignWrapper.RecipientWrapper recipient = recipientFieldMapping(acc, jo.Account__r.isPersonAccount, jo.Account__r.AccountNumber__c, '', 'JointOwner', 'Signer');
                        String joRole = '';

                        if(jo.Account__r.ResidentStatus__pc != null && jo.Account__r.ResidentStatus__pc == 'Resident'){
                            joRole += UAEPASSSIGNROLE + String.valueOf(signCount);
                            recipient.routingOrder = routingOrderResident;
                            routingOrderResident = routingOrderResident + 1;
                        } else {
                            joRole += IDNOWSIGNROLE + String.valueOf(signCount);
                            recipient.routingOrder = routingOrderNonResident;
                            routingOrderNonResident = routingOrderNonResident +  1;
                        }

                        recipient.role = joRole;
                        recipientList.add(recipient);
                        System.debug('recipient==> ' + recipient);
                        signCount++;
                    }
                }

                //add aldarSignatory 
                if(eSignGroup.contains(Constants.AUTHORISED_SIGNATORY_ESIGN) && recordTypeName == Constants.HANDOVER_RT) {
                    //Integer aldarSignSequence = 21;
                    DocuSignWrapper.AldarSignatories aldarSignatory = new DocuSignWrapper.AldarSignatories();
                    //recipient placeholders
                    DocuSignWrapper.RecipientTabs recipientPlaceHolders = new DocuSignWrapper.RecipientTabs();
                    recipientPlaceHolders.recipientSignHolder = 'AldarSignatureHolder';
                    recipientPlaceHolders.recipientDateHolder = 'AldarDateHolder';
                    recipientPlaceHolders.recipientInitialHolder = 'AldarInitialsHolder'; 
                    recipientPlaceHolders.recipientNameHolder = 'AldarNameHolder';

                    aldarSignatory.name = srDoc.HexaBPM__Service_Request__r.HOKAR__r.Name;
                    aldarSignatory.email = srDoc.HexaBPM__Service_Request__r.HOKAR__r.Email;
                    aldarSignatory.routingOrder = aldarSignSequence;
                    aldarSignatory.typeOfRecipient = '';
                    aldarSignatory.signatureType = '';
                    aldarSignatory.role = 'AldarUAEPassSign';
                    aldarSignatory.residentStatus = '';
                    aldarSignatory.typeOfCustomer = '';
                    aldarSignatory.signerType = 'Signer';
                    aldarSignatory.isStampRequired = false;
                    aldarSignatory.recipientPlaceHolders = recipientPlaceHolders;
                    aldarSignatoryList.add(aldarSignatory);
                } else if(eSignGroup.contains(Constants.AUTHORISED_SIGNATORY_ESIGN)) {
                    //add aldarSignatory 
                    //Integer aldarSignSequence = 21;
                    List<Aldar_Signatory_for_PT__mdt> aldarSignatories = [Select Id, Email__c, Order__c, Type__c, MasterLabel, DeveloperName, SigninggroupId__c, Signinggroupname__c FROM Aldar_Signatory_for_PT__mdt WHERE Active__c = true ORDER BY Order__c ASC];

                    for(Aldar_Signatory_for_PT__mdt aSign : aldarSignatories) {
                        if(aSign.Type__c == 'Approver'){
                            //recipient placeholders
                            DocuSignWrapper.RecipientTabs recipientPlaceHolders = new DocuSignWrapper.RecipientTabs();
                            
                            recipientPlaceHolders.recipientSignHolder = '--AA--';
                            recipientPlaceHolders.recipientDateHolder = '--AA--';
                            recipientPlaceHolders.recipientInitialHolder = '--AA--'; 
                            recipientPlaceHolders.recipientNameHolder = '--AA--';
                            

                            DocuSignWrapper.AldarSignatories aldarSignatory = new DocuSignWrapper.AldarSignatories();
                            aldarSignatory.name = aSign.DeveloperName;
                            aldarSignatory.email = aSign.Email__c;
                            aldarSignatory.routingOrder = aldarApproverSequence;
                            aldarSignatory.typeOfRecipient = '';
                            aldarSignatory.signatureType = '';
                            aldarSignatory.role = aSign.DeveloperName;
                            aldarSignatory.residentStatus = '';
                            aldarSignatory.typeOfCustomer = '';
                            aldarSignatory.signerType = 'Approver';
                            aldarSignatory.isStampRequired = false;
                            aldarSignatory.recipientPlaceHolders = recipientPlaceHolders;
                            aldarSignatoryList.add(aldarSignatory);
                        } else if(aSign.Type__c == 'Signatory') {
                            //recipient placeholders
                            DocuSignWrapper.RecipientTabs recipientPlaceHolders = new DocuSignWrapper.RecipientTabs();
                            recipientPlaceHolders.recipientSignHolder = 'AldarSignatureHolder';
                            recipientPlaceHolders.recipientDateHolder = 'AldarDateHolder';
                            recipientPlaceHolders.recipientInitialHolder = 'AldarInitialsHolder'; 
                            recipientPlaceHolders.recipientNameHolder = 'AldarNameHolder';

                            DocuSignWrapper.AldarSignatories aldarSignatory = new DocuSignWrapper.AldarSignatories();
                            aldarSignatory.name = aSign.DeveloperName;
                            aldarSignatory.email = aSign.Email__c;
                            aldarSignatory.routingOrder = aldarSignSequence;
                            aldarSignatory.typeOfRecipient = '';
                            aldarSignatory.signatureType = '';
                            aldarSignatory.role = 'AldarUAEPassSign';
                            aldarSignatory.residentStatus = '';
                            aldarSignatory.typeOfCustomer = '';
                            aldarSignatory.signerType = 'Signer';
                            aldarSignatory.isStampRequired = true;
                            aldarSignatory.recipientPlaceHolders = recipientPlaceHolders;
                            aldarSignatoryList.add(aldarSignatory);
                        }

                        aldarApproverSequence = aldarApproverSequence + 1;
                    }




                    /*List<Aldarsignatory__mdt> aldarSign = [Select Id, email__c, Order__c, Type__c, MasterLabel, DeveloperName, SigninggroupId__c, Signinggroupname__c FROM Aldarsignatory__mdt WHERE active__c = true ORDER BY Order__c];
                    //ALDAR SIGN
                    for(Aldarsignatory__mdt aSign : aldarSign) {
                        if(aSign.Type__c == 'Signatory'){
                            //recipient placeholders
                            DocuSignWrapper.RecipientTabs recipientPlaceHolders = new DocuSignWrapper.RecipientTabs();
                            recipientPlaceHolders.recipientSignHolder = 'AldarSignatureHolder';
                            recipientPlaceHolders.recipientDateHolder = 'AldarDateHolder';
                            recipientPlaceHolders.recipientInitialHolder = 'AldarInitialsHolder'; 
                            recipientPlaceHolders.recipientNameHolder = 'AldarNameHolder';

                            aldarSignatory.name = aSign.DeveloperName;
                            aldarSignatory.email = aSign.email__c;
                            aldarSignatory.routingOrder = aldarSignSequence;
                            aldarSignatory.typeOfRecipient = '';
                            aldarSignatory.signatureType = '';
                            aldarSignatory.role = 'AldarUAEPassSign';
                            aldarSignatory.residentStatus = '';
                            aldarSignatory.typeOfCustomer = '';
                            aldarSignatory.signerType = 'Signer';
                            aldarSignatory.isStampRequired = false;
                            aldarSignatory.recipientPlaceHolders = recipientPlaceHolders;
                        }
                    }*/
                }

                List<Aldar_Post_Sales_Email_Content__mdt> listEmailDomain = [SELECT Id, MasterLabel, Type__c, Email_Subject__c, Email_Body_Docusign_UAE_Pass_Link__c, Email_Body_Docusign_Id_Now_Link__c FROM Aldar_Post_Sales_Email_Content__mdt WHERE Type__c =:srDoc.HexaBPM__Service_Request__r.SRType__c LIMIT 1];
                
                if(listEmailDomain.isEmpty()){
                    return 'Unable to find email body content record';
                }

                Aldar_Post_Sales_Email_Content__mdt emailContent = listEmailDomain[0];
                String emailBody = '';
                String sub = emailContent.Email_Subject__c + ' ' + srDoc.HexaBPM__Service_Request__r.Unit__r.name;

              
                    if( srDoc.HexaBPM__Service_Request__r.BuyerName__r.ResidentStatus__pc != null 
                       && srDoc.HexaBPM__Service_Request__r.BuyerName__r.ResidentStatus__pc == 'Resident' && eSignGroup.contains(Constants.BUYER_ESIGN)){
                           emailBody += emailContent.Email_Body_Docusign_UAE_Pass_Link__c;
                           
                       } else if(srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc != null && srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc == 'Resident'){
                           emailBody += emailContent.Email_Body_Docusign_UAE_Pass_Link__c;
                       } else{
                           emailBody += emailContent.Email_Body_Docusign_Id_Now_Link__c;
                       }
                    if(srDoc.HexaBPM__Service_Request__r.SRType__c == Constants.PROPERTY_TRANSFER_NOC_SR_TYPE){
                         emailBody = emailBody.replace('{{MCDLINK}}', srDoc.HexaBPM__Service_Request__r.Unit__r.Project__r.MCD_Link__c);
                    }
                     
                
              


                //emailBody += Label.DOCUSIGN_EmailBody;
                //emailBody += '<a href="';
                
                /*if(srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc != null && srDoc.HexaBPM__Service_Request__r.HexaBPM__Customer__r.ResidentStatus__pc == 'Resident'){
                    emailBody += Label.DOCUSIGN_UAEPassLink;
                }else{
                    emailBody += Label.DOCUSIGN_IdNowLink;
                }*/

                //emailBody += '" target="_blank"> click here</a>';
                //emailBody += Label.DOCUSIGN_EmailBody2;   
                //emailBody += Label.DOCUSIGN_EmailBody3;
                System.debug('recipientList==> ' + recipientList);
                DocuSignWrapper.EnvelopeWrapper docusign = new DocuSignWrapper.EnvelopeWrapper();
                docusign.templateId = dfsle.UUID.parse(srDoc.HexaBPM__Document_Master__r.TemplateID__c);
                docusign.templateName = 'Aldar';
                docusign.documentRecordId = srDoc.Id;
                docusign.emailSubject = sub;
                docusign.emailBody = emailBody;
                docusign.contentVersion = contentVersionRecord;
                docusign.relatedObjectId = srDoc.HexaBPM__Service_Request__c;
                docusign.isNormalSign = false;
                docusign.recipients = recipientList;
                docusign.aldarSignatoryList = aldarSignatoryList;
                System.debug(docusign);
                dfsle.Envelope myEnvelope = DocuSignUtility.sendQESSignature(docusign);
                System.debug('myEnvelope=> ' + myEnvelope);
                myEnvelope = test.isRunningTest() ? null : dfsle.EnvelopeService.sendEnvelope(myEnvelope, true);
               
                String likedSignedString = '';
                likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_SIGNED + ' ' + srDoc.Name;
                List<HexaBPM__SR_Doc__c> relatedSignDocumentList = [SELECT Id, HexaBPM__Service_Request__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :srDoc.HexaBPM__Service_Request__c AND  Name = :likedSignedString];
                
                if(srDoc.Name == Constants.DOCUMENT_UNIFIED_HANDOVER_DOCUMENTS && srDoc.HexaBPM__Service_Request__r.HandoverDetail__c != NULL) {
                    HandoverDetails__c handoverDetails = new HandoverDetails__c();
                    handoverDetails.Id = srDoc.HexaBPM__Service_Request__r.HandoverDetail__c;
                    handoverDetails.Docusign_Sent_Date__c = System.today();
                    update handoverDetails;
                }

                if(!relatedSignDocumentList.isEmpty()){
                    HexaBPM__SR_Doc__c relatedSignDocument = relatedSignDocumentList[0];
                    String docuSignID = test.isRunningTest() ? 'Test' : String.valueOf(myEnvelope.docuSignId);
                    relatedSignDocument.Docusign_Envelope_Id__c = docuSignID;
                    srDoc.Send_For_E_Signature__c = false;

                    if(srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.ResidentStatus__pc != null && srDoc.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.ResidentStatus__pc == 'Resident') {
                        srDoc.EsignLocation__c = 'UAE Pass';
                    } else {
                        srDoc.EsignLocation__c = 'IDNow';
                    }

                    update new list<HexaBPM__SR_Doc__c>{relatedSignDocument, srDoc};
                }

                return Constants.SUCCESS_MESSAGE;
            } else {
                return 'Unable to find record';
            }
        } catch(Exception e) {
            System.debug(' **** Docusign Exception ****'+e);
            //getLineNumber
            return e.getMessage() + e.getLineNumber();
        }
    }

    public static DocuSignWrapper.RecipientWrapper recipientFieldMapping(Account acc, Boolean isPersonAccount, String accountNumber, String role, String typeOfRecipient, String signerType){
        DocuSignWrapper.RecipientWrapper recipient = new DocuSignWrapper.RecipientWrapper();
        recipient.name = acc.Name;
        recipient.email = isPersonAccount ? acc.PersonEmail : acc.Email__c;
        recipient.role = role;
        recipient.signatureType = 'Digital Signature';
        recipient.residentStatus = acc.ResidentStatus__pc;
        recipient.typeOfCustomer = isPersonAccount ? 'Individual' : 'Organization';
        recipient.signerType = signerType;
        recipient.isStampRequired = false;
        recipient.typeOfRecipient = typeOfRecipient;
        recipient.aldarSign = new Aldarsignatory__mdt();
        //recipient placeholders
        DocuSignWrapper.RecipientTabs recipientPlaceHolders = new DocuSignWrapper.RecipientTabs();
        recipientPlaceHolders.recipientSignHolder = isPersonAccount ? accountNumber + 'SignatureHolder' : accountNumber + 'OrgSignatureHolder';
        recipientPlaceHolders.recipientDateHolder = isPersonAccount ? accountNumber + 'DateHolder' : accountNumber + 'OrgDateHolder';
        recipientPlaceHolders.recipientInitialHolder = isPersonAccount ? accountNumber + 'InitialsHolder' : accountNumber + 'OrgInitialsHolder'; 
        recipientPlaceHolders.recipientNameHolder = isPersonAccount ? accountNumber + 'NameHolder' : accountNumber + 'OrgNameHolder';
        recipient.recipientPlaceHolders = recipientPlaceHolders;
        return recipient;
    }
}