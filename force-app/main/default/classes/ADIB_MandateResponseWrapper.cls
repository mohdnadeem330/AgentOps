public class ADIB_MandateResponseWrapper{
	public cl_context context;
	public cls_payload payload;
	public class cl_context {
		public String userId;
		public String interfaceId;
		public String groupCustomerCode;
		public String customerGuid;
		public String customerCode;
		public String channelRefNumber;
		public String channelId;
		public String branchCode;
		public String bankEntityId;	
		public String bankCode;	
		public String entityCode;
		public String status;	
		public String errorCode;
		public String errorMessage;	
		public String authChannelId;
		public String authChannelRefNumber;
	}
	public class cls_payload {
		public String rangeUpTo;	
		public String referenceNo;	
		public String vaIbanRangeUpto;	
		public String vaIbanRangeFrom;	
		public String rangeFrom;
	}
	
}