/*
*********************************************************
Apex Class Name    : DocuSignWrapper
Created Date       : June 23, 2023
@description       : This is class is used for 
@author            : Moh Sarfaraj
Modification Log:
Ver   Date              Author                               Modification
1.0   23-06-2023      Moh Sarfaraj                          Initial Version
*********************************************************
*/
public class DocuSignWrapper {

    public class EnvelopeWrapper{
        public dfsle.UUID templateId;// Required
        public String templateName;
        public String documentRecordId;  // Required
        public String emailSubject;
        public String emailBody;
        public ContentVersion contentVersion;// Required
        public String relatedObjectId; // Account Id/ contact Id
        public Boolean isNormalSign;
        public List<RecipientWrapper> recipients;// Required
        public List<AldarSignatories> aldarSignatoryList;
    }
   
    public class RecipientTabs{
        public String recipientSignHolder;
        public String recipientDateHolder;
        public String recipientInitialHolder;
        public String recipientNameHolder;
        public dfsle.Tab recipientStampHolder;
    }     

    public class RecipientWrapper{
        public String name;// Required
        public String email;// Required
        public Integer routingOrder;// Required
        public String typeOfRecipient; // (PrimaryRecipient/JointOwner/AldarSignatory/Seller/Buyer/AldarApprover)
        public String signatureType; // (Digital Signature/UAE Pass/IDNow)
        public String role;  // Required
        public String residentStatus;
        public String typeOfCustomer; //  (Individual/Organization) 
        public String signerType;// Required
        public Boolean isStampRequired = false;
        public Aldarsignatory__mdt aldarSign;
        public RecipientTabs recipientPlaceHolders;// Required
    }

    public class AldarSignatories{
        public String name;// Required
        public String email;// Required
        public Integer routingOrder;// Required
        public String typeOfRecipient; // (PrimaryRecipient/JointOwner/AldarSignatory/Seller/Buyer/AldarApprover)
        public String signatureType; // (Digital Signature/UAE Pass/IDNow)
        public String role;  // Required
        public String residentStatus;
        public String typeOfCustomer; //  (Individual/Organization) 
        public String signerType;// Required
        public Boolean isStampRequired = false;
        public RecipientTabs recipientPlaceHolders;// Required
    }

    public class Signer{
        public String type;
        public Id primaryCustomerId;
        public Set<Id> relatedSObjectIds;
        public Signer(Id customerId, Id relatedSObjectId, String type){
            this.primaryCustomerId = customerId;
            this.relatedSObjectIds = new Set<Id>{relatedSObjectId};
            this.type = type;
        }
    }
}