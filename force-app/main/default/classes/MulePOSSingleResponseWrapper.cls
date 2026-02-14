// MulePOSSingleResponseWrapper -> Mule Post Sales Single Response Wrapper -> results will be only one
public class MulePOSSingleResponseWrapper {
    public String applicationName;	//x-ald-sferp-api
    public boolean success;
    public String statusCode;	//201
    public String correlationId;	//e6d316c0-1cc6-11ee-bc15-0642d748900e
    public Results results;
    public class Results {
        public PrpTransRs[] prpTransRs;
        public CancellationRes[] cancellationRes;
    }
    public class PrpTransRs {
        public String sfRequestId;	//e6d316c0-1cc6-11ee-bc15-0642d748900e
        public String srSFId;	//a0Q25000005AvrLEAS
        public String srERPId;	//2310061
        public String status;	//Success
        public String errorMsg;	//
        public PrpTransJORs[] prpTransJORs;
        public OthChgRes[] othChgRes;
    }
    public class PrpTransJORs {
        public String cusERPId;	//2310061
        public String soSFId;	//Success
        public String cusSFId;	//
    }
    public class OthChgRes {
        public String sfRequestId;	//e6d316c0-1cc6-11ee-bc15-0642d748900e
        public String srSFId;	//a0Q25000005AvrLEAS
        public String sfId;	//a292500000236O3AAI
        public String erpId;	//9061879
        public String recAcct;	//02.10.A439017.122101.02.00.000.000
        public String expAcct;	//02.10.A439017.233167.02.00.000.000
        public String taxAcct;	//02.10.A439017.233169.02.00.000.000
        public String status;	//Success
        public String errorMsg;	//
        public String invoiceNo;	//70083130
    }
    
    
    public class CancellationRes {
		public String sfRequestId;	//b33074e0-2241-11ee-ba35-06b067bb389c
		public String srSFId;	//a0Q25000005B7GLEA0
		public String sfSalesOrderId;	//a2A8d000000LeHlEAK
		public String status;	//Success
		public String errorMsg;	//
        public OthChgRes[] othChgRes;
		public CreditNoteRes[] creditNoteRes;
	}
    public class CreditNoteRes {
		public String sfRequestId;	//b33074e0-2241-11ee-ba35-06b067bb389c
		public String srSFId;	//a0Q25000005B7GLEA0
		public String sfSalesOrderId;	//a2A8d000000LeHlEAK
		public String type;	//Credit Note
		public String instNum;	//1
		public String invoiceId;	//8264893
		public String cnErpId;	//9061917
		public String status;	//Success
		public String errorMsg;	//
	}
    /*public static MulePOSSingleResponseWrapper parse(String json){
        return (MulePOSSingleResponseWrapper) System.JSON.deserialize(json, MulePOSSingleResponseWrapper.class);
    }*/
}