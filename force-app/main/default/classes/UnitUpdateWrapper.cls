public class UnitUpdateWrapper{
	
	public class PriceUpdateUnits {
		public PriceUpdateUnitRecord[] priceUpdateUnitRecords;

		public PriceUpdateUnits(List<PriceUpdateUnitRecord> records){
			this.priceUpdateUnitRecords = records ;
		}
	}

	public class StatusUpdateUnits {
		public StatusUpdateUnitRecord[] statusUpdateUnitRecords;

		public StatusUpdateUnits(List<StatusUpdateUnitRecord> records){
			this.statusUpdateUnitRecords = records ;
		}
	}
	
	public class PriceUpdateUnitRecord {
		public Decimal unitPrice;	
		public String remarks;	
		public Decimal revisionNumber;	
		public String recordId;	
		public String unitCode;	

		public PriceUpdateUnitRecord(Unit__c unitRecord){
			this.unitPrice = unitRecord.SellingPrice__c ;
			this.remarks = unitRecord.SellingPriceComments__c ;
			this.revisionNumber = unitRecord.SellingPriceRevisionNumber__c ;
			this.recordId = unitRecord.Id ;
			this.unitCode = unitRecord.Name ;
		}
		
	}
		
	public class StatusUpdateUnitRecord{
		public String unitCode;
		public String status;	
		public String actionedBy;	
		public String blockedComments;	
		public String blockedReason;	
		public String recordId;	
		public String assignedTo;	
		public String allocationGroup;	

		public StatusUpdateUnitRecord(Unit__c unitRecord){
			this.unitCode = unitRecord.Name ;
			this.recordId = unitRecord.Id ;
			this.status = unitRecord.Status__c ;
			this.actionedBy = UserInfo.getUserEmail();
			this.blockedReason = unitRecord.BlockedReason__c != null ? unitRecord.BlockedReason__c : '';
			this.blockedComments = unitRecord.BlockedComments__c != null ? unitRecord.BlockedComments__c : '';
			this.assignedTo = unitRecord.AssignedToUserEmail__c != null ? unitRecord.AssignedToUserEmail__c : '';
			this.allocationGroup = unitRecord.AllocationGroupCode__c != null ? unitRecord.AllocationGroupCode__c : '';
		}
	}

}