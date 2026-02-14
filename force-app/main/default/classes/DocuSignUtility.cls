/*
*****************************************************************************
Apex Class Name    : DocuSignUtility
Created Date       : June 22, 2023
@description       :  
@author            : Moh Sarfaraj
Modification Log:
Ver   Date              Author                               Modification
1.0   22-06-2023      Moh Sarfaraj                          Initial Version
******************************************************************************
*/
public class DocuSignUtility{
    /*
    ************************************************************************************
    @Method Name    : sendQESSignature
    @author         : Moh Sarfaraj
    @description    : It's used to get generiuc Esign Envelope for each type of recipient
    @param          : DocuSignWrapper.EnvelopeWrapper
    @return         : dfsle.Envelope
    *************************************************************************************
    */
    public static dfsle.Envelope sendQESSignature(DocuSignWrapper.EnvelopeWrapper envelopeRecord){
        dfsle.Envelope myEnvelope;
        if(envelopeRecord != null){
            List<dfsle.Recipient> recipientList =  new List<dfsle.Recipient>();
            
            // Create an empty envelope. with the DocID
            myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(envelopeRecord.documentRecordId));
            // templateId in dfsle.UUID format // name of the template
            dfsle.Document myDocument;

            if(envelopeRecord.recipients != null && !envelopeRecord.recipients.isEmpty()){
                if(!envelopeRecord.isNormalSign){
                    if(envelopeRecord.templateId != null &&  String.isNotBlank(envelopeRecord.templateName)){
                        // templateId in dfsle.UUID format // name of the template
                        myDocument = dfsle.Document.fromTemplate(envelopeRecord.templateId, envelopeRecord.templateName); 
                    }
                }
                // Iterating Recipients loop each type of Recipient
                for(DocuSignWrapper.RecipientWrapper eachRecipient : envelopeRecord.recipients){
                    recipientList.add( 
                        prepareSignaturePlaceholder(
                            eachRecipient?.signatureType,
                            eachRecipient?.signerType, // 'singer/approver'
                            eachRecipient?.role, 
                            eachRecipient?.recipientPlaceHolders?.recipientSignHolder,
                            eachRecipient?.recipientPlaceHolders?.recipientDateHolder,
                            eachRecipient?.recipientPlaceHolders?.recipientInitialHolder,
                            eachRecipient?.name,
                            eachRecipient?.email,
                            envelopeRecord?.documentRecordId,
                            eachRecipient?.routingOrder,
                            eachRecipient?.aldarSign,
                            eachRecipient.recipientPlaceHolders.recipientStampHolder = eachRecipient.isStampRequired ? getStamp() : null,
                            eachRecipient?.recipientPlaceHolders?.recipientNameHolder
                        )
                    );
                }
                
                if(envelopeRecord.aldarSignatoryList != null && !envelopeRecord.aldarSignatoryList.isEmpty()){
                     // Iterating aldarSignatory loop each type of aldarSignatory
                    for(DocuSignWrapper.AldarSignatories aldarSignatory : envelopeRecord.aldarSignatoryList) {
                        recipientList.add( 
                            prepareSignaturePlaceholder(
                                aldarSignatory?.signatureType,
                                aldarSignatory?.signerType, // 'singer/approver'
                                aldarSignatory?.role, 
                                aldarSignatory?.recipientPlaceHolders?.recipientSignHolder,
                                aldarSignatory?.recipientPlaceHolders?.recipientDateHolder,
                                aldarSignatory?.recipientPlaceHolders?.recipientInitialHolder,
                                aldarSignatory?.name,
                                aldarSignatory?.email,
                                envelopeRecord?.documentRecordId,
                                aldarSignatory?.routingOrder,
                                null,
                                getStamp(),
                                aldarSignatory?.recipientPlaceHolders?.recipientNameHolder
                            )
                        );
                    }
                }

                if(!recipientList.isEmpty()){
                    // Add Recipient to the Envelope
                    myEnvelope = myEnvelope.withRecipients(recipientList);
                        
                    // set Subject and Body of an email for QES Envelope
                    if(!envelopeRecord.isNormalSign && myDocument != null){
                        if(String.isNotBlank(envelopeRecord.emailSubject) && String.isNotBlank(envelopeRecord.emailBody)){
                            myEnvelope = myEnvelope.withEmail(envelopeRecord.emailSubject, envelopeRecord.emailBody);
                        }
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
                        myDocument.withReplacement(dfsle.Document.fromFile(envelopeRecord.contentVersion));
                        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
                    }
                    else{
                        // set document to the Envelope for normal Singnature
                        myEnvelope = myEnvelope.withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(), new Set<Id>{envelopeRecord.contentVersion.Id}));
                    }
                    return myEnvelope;
                }
            }
        }
        return myEnvelope;
    }

    /*
    *********************************************************
    @Method Name    : sendNormalSignature
    @author         : Moh Sarfaraj
    @description    : It's used to get generic normal esign
    @return         : dfsle.Envelope
    ********************************************************
    */
    /*public static dfsle.Envelope sendNormalSignature(DocuSignWrapper.EnvelopeWrapper envelopeRecord){
        dfsle.Envelope myEnvelope;
        if(envelopeRecord != null){
            myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope( new dfsle.Entity(envelopeRecord.documentRecordId));
            dfsle.Tab signatureTab;
            dfsle.Tab dateTab;
            dfsle.Tab initialHereTab;
            dfsle.Recipient myRecipient;
            
            signatureTab = DownloadSODocsController.createEnvTab( envelopeRecord.relatedObjectId + 'SignatureHolder');
            
            dateTab = DownloadSODocsController.createEnvTab( envelopeRecord.relatedObjectId + 'DateHolder');
            initialHereTab = DownloadSODocsController.createEnvTab( envelopeRecord.relatedObjectId + 'InitialsHolder');
            // Add Recipient Salesorder's Account or Account's Primary Contact (must be present)
            
            String recipitName = envelopeRecord.recipients[0].name;
            String recipitEmail = envelopeRecord.recipients[0].email;
            myRecipient = dfsle.Recipient.fromSource(recipitName,recipitEmail,
                                                                null, // Optional phone number
                                                                null, // Role Name. Specify the exact role name from template
                                                                new dfsle.Entity(envelopeRecord.relatedObjectId))
                    .withTabs(new List<dfsle.Tab> {signatureTab, dateTab, initialHereTab}); // Source object for the Recipient
            
            // Add Recipient to the Envelope
            myEnvelope = myEnvelope.withRecipients(new List<dfsle.Recipient> { myRecipient });
        
            // Add Recipient to the Envelope
            myEnvelope = myEnvelope.withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(), new Set<Id>{envelopeRecord.contentVersion.Id}));
        }
        return myEnvelope;
    }*/

    /*
    *********************************************************
    @Method Name    : prepareSignaturePlaceholder
    @author         : Moh Sarfaraj
    @description    : It's used to prepare signature for Envelope for each type of recipients
    @param          : String
    @param          : String
    @param          : String
    @param          : String
    @param          : String
    @param          : String
    @param          : String
    @param          : String
    @param          : Integer
    @param          : Aldarsignatory__mdt
    @param          : dfsle.Tab
    @param          : String
    @return         : dfsle.Recipient
    ********************************************************
    */
    public static dfsle.Recipient prepareSignaturePlaceholder(String signatureType,String signerType, String roleStr, String signUniqueId,
                                                              String dateUniqueId, String initialUniqueID, String recipientName,
                                                              String recipientEmail, String relatedId, Integer routingOrder,
                                                              Aldarsignatory__mdt aldarSign, dfsle.Tab myStampTab, String nameUniqueID){

        dfsle.Recipient myRecipient;
        dfsle.Tab signatureTab = DownloadSODocsController.createEnvTab(signUniqueId);
        dfsle.Tab dateTab = DownloadSODocsController.createEnvTab(dateUniqueId);
        dfsle.Tab initialHereTab = DownloadSODocsController.createEnvTab(initialUniqueID);
        dfsle.Tab nameTab = DownloadSODocsController.createEnvTab(nameUniqueID);

        if(signatureType != 'Normal Signature'){
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
            }
        }else{
            myRecipient = dfsle.Recipient.fromSource(recipientName,recipientEmail,
                                                                null, // Optional phone number
                                                                null, // Role Name. Specify the exact role name from template
                                                                new dfsle.Entity(relatedId))
                    .withTabs(new List<dfsle.Tab> {signatureTab, dateTab, initialHereTab}); // Source object for the Recipient
            
        }
        return myRecipient;
    }

    /*
    *********************************************************
    @Method Name    : getStamp
    @author         : Moh Sarfaraj
    @description    : It's used to prepare stamp for Envelope 
                      for each type of recipients
    ********************************************************
    */
    public static dfsle.Tab getStamp(){
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
        return myStampTab;
    }
}