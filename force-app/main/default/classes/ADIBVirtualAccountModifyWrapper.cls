public class ADIBVirtualAccountModifyWrapper {
    
    public Payload payload;
	public Context context;
    
    public class Context {
		public String interfaceId;
		public String channelId;
		public String channelRefNumber;
		public String bankEntityId;
		public String groupCustomerCode;
		public String customerCode;
		public String customerGuid;
		public String bankCode;
		public String branchCode;
		public String userId;
	}

	public class VirtualAccounts {
		public String parentVirtualAccountNumber;
		public String vaType;
		public String virtualAccountNumber;
		public String virtualAccountName;
        public String vaAliasName;
		//public String counterPartyId;
		//public String counterPartyPercentage;
		//public String counterpartyPayoutAccNum;
		//public String counterpartyPayoutAccName;
		//public String counterpartyPayoutAccCurr;
		//public String counterpartyPayoutAccBic;
		//public String countryCode;
		//public String stateCode;
		//public String postalCode;
		//public String city;
		//public String address1;
		//public String address2;
		//public String address3;
		//public String phoneNumber;
		//public String mobileNumber;
		//public String emailAddress1;
		public String remarks1;
		public String status;
        //public String vaCreditAllowed;
        //public String vaDebitAllowed;
        //public String vaBalance;
	}

	public class Payload {
		public VirtualAccounts virtualAccounts;
        public String customerRootVa;
        public String cif;
	}

}