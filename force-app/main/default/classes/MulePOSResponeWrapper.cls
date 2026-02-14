// MulePOSResponeWrapper -> Mule Post Sales Response Wrapper
public class MulePOSResponeWrapper {
    public String applicationName;    //x-ald-sferp-api
    public boolean success;
    public String statusCode;    //201
    public String correlationId;    //09e34b10-1fd5-11ee-ba35-06b067bb389c
    public Results[] results;
    public class Results {
        public LpcRes[] lpcRes;
        public PmtPlanRes[] pmtPlanRes;
		public InstLinesRes[] instLinesRes;
    }
    public class PmtPlanRes {
		public String sfRequestId;	//a0Q8d000005yj58EAA
		public String sfSalesOrderNum;	//a2A8d000000LfHdEAK
		public String erpSalesOrderId;	//92846
		public String erpPayPlanId;	//
		public String erpCustAcctId;	//
		public String status;	//Success
		public String errorMsg;	//
	}
	public class InstLinesRes {
		public String sfRequestId;	//a0Q8d000005yj58EAA
		public String sfSalesOrderNum;	//a2A8d000000LfHdEAK
		public String sfInstId;	//a1g8d000000d5NvAAI
		public String erpInstId;	//361034
		public String status;	//Success
		public String errorMsg;	//
	}
    public class LpcRes {
        public String sfRequestId;    //09e34b10-1fd5-11ee-ba35-06b067bb389c
        public String srSfid;    //a0Q25000005B2VUEA0
        public String sfSalesorderId;    //a2A8d000000LermEAC
        public String sfId;    //a0Q25000005B2VUEA0
        public String erpId;    //
        public String status;    //Success
        public String errorMsg;    //
        public OthChgRes[] othChgRes;
    }
    public class OthChgRes {
        public String sfRequestId;    //09e34b10-1fd5-11ee-ba35-06b067bb389c
        public String srSFId;    //a0Q25000005B2VUEA0
        public String sfId;    //a29250000023AlSAAU
        public String erpId;    //9061894
        public String recAcct;    //02.10.A439017.123119.02.00.000.000
        public String expAcct;    //02.10.A439017.421102.02.00.000.000
        public String taxAcct;    //02.10.A439017.233169.02.00.000.000
        public String status;    //Success
        public String errorMsg;    //
        public String invoiceNo;    //70083134
    }
    /*public static MulePOSResponeWrapper parse(String json){
        return (MulePOSResponeWrapper) System.JSON.deserialize(json, MulePOSResponeWrapper.class);
    }*/
}