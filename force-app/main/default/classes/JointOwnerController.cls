public with sharing class JointOwnerController {

    public class JointOwnerModel {
        public String accountId;
        public String accountName;
        public String unitNumber;
        public String unitId;
        public String salesOrderNo;
        public String salesOrderId;
        public String srType;
        public List<JointOwnerDetailModel> jointOwnerDetailList;
        public List<JointOwnerDetailModel> subJointOwnerList;
        public List<JointOwnerDetailModel> relatedAccountList;
    }

    public class JointOwnerDetailModel {
        public String Id;
        public String accountId;
        public String accountName;
        public String jointOwner;
        public String jointOwnerId;
        public String ownershipType;
        public String relationType;
        public String newRelationType;
        public Decimal sharePercentage;
        public String description;

        public JointOwnerDetailModel() {}

        public JointOwnerDetailModel(String accountId, String accountName, String relationType, Decimal sharePercentage) {
            this.accountId = accountId;
            this.jointOwner = accountName;
            this.accountName = accountName;
            if (relationType == Constants.PRIMARY_OWNER) {
                this.ownershipType = relationType;
            } else {
                this.relationType = relationType;
            }
            this.sharePercentage = sharePercentage;
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getServiceRequestDetail(Id srId){
        JointOwnerModel returnJointOwnerModel = new JointOwnerModel();
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId})[0];
        SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];

        Set<Id> accountIdSet = new Set<Id>();
        
        returnJointOwnerModel.accountId = serviceRequest.BuyerName__c != null ? serviceRequest.BuyerName__c : salesOrder.Account__c;
        returnJointOwnerModel.accountName = serviceRequest.BuyerName__c != null ? serviceRequest.BuyerName__r.Name : salesOrder.Account__r.Name;
        returnJointOwnerModel.unitNumber = serviceRequest.Unit__r.Name;
        returnJointOwnerModel.unitId = serviceRequest.Unit__c;
        returnJointOwnerModel.salesOrderNo = serviceRequest.SalesOrder__r.Name;
        returnJointOwnerModel.salesOrderId = serviceRequest.SalesOrder__c;
        returnJointOwnerModel.srType = serviceRequest.SRType__c;
        
        List<JointOwnerDetailModel> jointOwnerDetailList = new List<JointOwnerDetailModel>();
        Decimal totalSharePercentage = 0;
        if (!serviceRequest.Partners__r.isEmpty()) {
            for (AgencyTeam__c srAmendment: serviceRequest.Partners__r) {
                totalSharePercentage += (srAmendment.ShareHoldingPercentage__c != null ? srAmendment.ShareHoldingPercentage__c : 0);
                JointOwnerDetailModel joDetailModel = new JointOwnerDetailModel(srAmendment.Account__c, srAmendment.Account__r.Name, srAmendment.RelationshipType__c, srAmendment.ShareHoldingPercentage__c);
                joDetailModel.Id = srAmendment.Id;
                joDetailModel.jointOwnerId = srAmendment.RelationshipType__c == Constants.PRIMARY_OWNER ? salesOrder.Id : srAmendment.JointOwner__c;
                accountIdSet.add(srAmendment.Account__c);
                // if (serviceRequest.SRType__c == Constants.OWNERSHIP_CHANGE_RT && String.isNotBlank(srAmendment.Description__c)) {
                //     joDetailModel.relationType = srAmendment.RelationshipType__c != Constants.PRIMARY_OWNER ? srAmendment.Description__c : '';
                //     joDetailModel.ownershipType = srAmendment.Description__c == Constants.PRIMARY_OWNER ? srAmendment.Description__c : '';
                //     joDetailModel.newRelationType = srAmendment.RelationshipType__c;
                // }
                if (String.isNotBlank(srAmendment.Description__c)) {
                    joDetailModel.newRelationType = srAmendment.Description__c;
                } else {
                    joDetailModel.newRelationType = Constants.JOINT_OWNER_RT;
                }
                jointOwnerDetailList.add(joDetailModel);
            }
        }
        returnJointOwnerModel.jointOwnerDetailList = jointOwnerDetailList;
        
        List<JointOwnerDetailModel> subJointOwnerList = new List<JointOwnerDetailModel>();
        for (JointOwner__c jointOwner: salesOrder.Joint_OwnersSalesOrder__r) {
            if (accountIdSet.contains(jointOwner.Account__c)) {
                continue;
            }
            totalSharePercentage += (jointOwner.SharePercentage__c != null ? jointOwner.SharePercentage__c : 0);
            JointOwnerDetailModel joDetailModel = new JointOwnerDetailModel(jointOwner.Account__c, jointOwner.Account__r.Name, jointOwner.RelationshipType__c, jointOwner.SharePercentage__c);
            joDetailModel.jointOwnerId = jointOwner.Id;
            joDetailModel.Id = jointOwner.Id;
            joDetailModel.newRelationType = Constants.JOINT_OWNER_RT;
            subJointOwnerList.add(joDetailModel);
        }
        
        if (serviceRequest.Partners__r.isEmpty()) {
            JointOwnerDetailModel joDetail = new JointOwnerDetailModel(salesOrder.Account__c, salesOrder.Account__r.Name, '', (100 - totalSharePercentage));
            joDetail.jointOwnerId = salesOrder.Id;
            joDetail.Id = salesOrder.Id;
            joDetail.ownershipType = Constants.PRIMARY_OWNER;
            joDetail.newRelationType = Constants.PRIMARY_OWNER;
            subJointOwnerList.add(joDetail);
        }
        returnJointOwnerModel.subJointOwnerList = subJointOwnerList;

        List<AccountRelationship__c> accountRelationshipList = AccountRelationshipService.getAccountRelationshipFromAccountId(returnJointOwnerModel.accountId);
        List<JointOwnerDetailModel> relatedAccountList = new List<JointOwnerDetailModel>();
        if (!accountRelationshipList.isEmpty()) {
            for (AccountRelationship__c accountRelationship: accountRelationshipList) {
                JointOwnerDetailModel joDetailModel = new JointOwnerDetailModel(accountRelationship.RelatedAccount__c, accountRelationship.RelatedAccount__r.Name, accountRelationship.RelationshipType__c, 0);
                relatedAccountList.add(joDetailModel);
            }
        }
        returnJointOwnerModel.relatedAccountList = relatedAccountList;

        System.debug('returnJointOwnerModel>>>' + JSON.serialize(returnJointOwnerModel));
        return JSON.serialize(returnJointOwnerModel);
    }

    @AuraEnabled(cacheable=false)
    public static String saveJointOwner(String jointOwner, Id srId, String deleteNewJO){
        try {
            System.debug('jointOwner>>>' + jointOwner);
            Id recordTypeId = Utilities.getRecordTypeId('AgencyTeam__c', Constants.JOINT_OWNER_RT);
            List<JointOwnerDetailModel> jointOwnerList = (List<JointOwnerDetailModel>)json.deserialize(jointOwner, List<JointOwnerDetailModel>.Class);
            
            List<AgencyTeam__c> updateAgencyTeamList = new List<AgencyTeam__c>();
            for (JointOwnerDetailModel jo: jointOwnerList) {
                AgencyTeam__c updateAgencyTeam = new AgencyTeam__c();
                if(String.isNotBlank(jo.Id) && jo.jointOwnerId != jo.Id) {
                    updateAgencyTeam.Id = jo.Id;
                } else {
                    updateAgencyTeam.ServiceRequest__c = srId;
                    updateAgencyTeam.RecordTypeId = recordTypeId;
                }

                updateAgencyTeam.Name = jo.accountName;
                updateAgencyTeam.Account__c = jo.accountId;
                updateAgencyTeam.Description__c = jo.newRelationType;
                updateAgencyTeam.RelationshipType__c = String.isNotBlank(jo.relationType) ? jo.relationType : jo.ownershipType;
                
                updateAgencyTeam.ShareHoldingPercentage__c = jo.sharePercentage;
                if(String.isNotBlank(jo.jointOwnerId) && jo.ownershipType != Constants.PRIMARY_OWNER) {
                    updateAgencyTeam.JointOwner__c = jo.jointOwnerId;
                }
                updateAgencyTeamList.add(updateAgencyTeam);

                if(jo.ownershipType == Constants.PRIMARY_OWNER) {
                    HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c();
                    serviceRequest.Id = srId;
                    serviceRequest.BuyerName__c = jo.accountId;
                    update serviceRequest;
                    System.debug('serviceRequest>>>' + serviceRequest);
                }
            }
            if (String.isNotBlank(deleteNewJO)) {
                List<AgencyTeam__c> deleteJOList = new List<AgencyTeam__c>();
                if (deleteNewJO.contains(',')) {
                    for (String joId: deleteNewJO.split(',')) {
                        AgencyTeam__c deleteJO = new AgencyTeam__c();
                        deleteJO.Id = joId;
                        deleteJOList.add(deleteJO);
                    }
                } else {
                    AgencyTeam__c deleteJO = new AgencyTeam__c();
                    deleteJO.Id = deleteNewJO;
                    deleteJOList.add(deleteJO);
                }
                delete deleteJOList;
            }
            if (!updateAgencyTeamList.isEmpty()) {
                System.debug('updateAgencyTeamList>>>'+ JSON.serialize(updateAgencyTeamList));
                upsert updateAgencyTeamList;
            }
        } catch (Exception ex) {
            System.debug('Error>>>'+ ex.getMessage());
            throw ex;
        }
        return 'Success';
    }
}