public class QuarterlyBrokerRequestPayload {
	public String Id;
	public String OwnerId;
	public Boolean IsDeleted;
	public String Name;
	public String CurrencyIsoCode;
	public Datetime CreatedDate;
	public String CreatedById;
	public Datetime LastModifiedDate;
	public String LastModifiedById;
	public DAtetime SystemModstamp;
	public DAtetime LastActivityDate;
	public String ApprovalStatus;
	public String BrokerAgency;
	public String CommentTrail;
	public String Comments;
	public String Quarter;
	public String Status;
	public String Year;
    public String quarterlyBonusInvoiceFormDocURL;
    public String quarterlyBonusInvoiceFormDocId;
	public CommissionLineItem CommissionLineItems;

	public class CommissionLineItem {
		public List<Records> records;
	}

	public class BrokerAgency {
		public String Name;
		public String BrokerClassificationFormula;
	}
    
    public class Unit {
		public String Name;
        public String BuildingSectionNameId;
        public String BuildingSectionName;
	}

	public class SalesOrder {
		public String Name;
	}

	public class Records {
		public String Id;
		public String Name;
		public String BrokerAgencyId;
		public BrokerAgency BrokerAgency;
		public Double CommissionAmount;
		public String UnitId;
		public Unit Unit;
		public String SalesOrderId;
		public SalesOrder SalesOrder;
		public Date OrderDate;
		public Double CommissionPercentage;
		public Decimal NetAmount;
	}
     public static QuarterlyBrokerRequestPayload parse(String json){
		return (QuarterlyBrokerRequestPayload) System.JSON.deserialize(json, QuarterlyBrokerRequestPayload.class);
	}
}