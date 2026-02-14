public class TasareehIntegration_Parser{
	public cls_B1Permits[] B1Permits;
	public cls_BuildingDetails[] BuildingDetails;
	public cls_Documents[] Documents;
	public cls_Fees[] Fees;
	public cls_Inspections[] Inspections;
	public cls_Parcels[] Parcels;
	public cls_Permits[] Permits;
	public cls_PermitsCustomProperties[] PermitsCustomProperties;
	public cls_Professionals[] Professionals;
	public cls_StatusHistory[] StatusHistory;
	public cls_WorkflowTasks[] WorkflowTasks;
	public cls_WorkflowHistory[] WorkflowHistory;
    public cls_paymentRequest[] Payments;
    
    public class cls_paymentRequest {
        public String RecordId;	//B1N-2023-003333-P01-I03
        public String RecordSubmissionDate;	//2023-10-12 11:47:25.227
        public String RecordRequestType;	//Inspection Request
        public String FeesDescription;	//TASREEH review fees
        public String FeesCode;	//BLD_TASREEH
        public String gf_fee_schedule;	//TASREEH
        public String InvoiceNBR;	//228012
        public String TransactionCode;	//202328988160651
        public String PaymentMethod;	//Online
        public String PaymentDate;	//2023-10-16 10:13:10.087
        public Decimal Amount;	//1200        
    }
 
    public class cls_B1Permits {
		public String ServiceCode;	//WRKP
		public String RecordId;	//B1S-2022-000021-WKT03
		public String RecordStatus;	//Submitted
		public String RecordStatusArabic;	//تم تقديم الطلب
		public String RecordClass;	//COMPLETE
		public Decimal Balance;	//0
		public String ProjectDescription;	//dd
		public String LastStatusDate;	//2023-01-04 00:00:00.0
		public String SubmissionDate;	//2023-01-04 08:48:05.577
		public String Sector;	//MW4
		public String PlotNumber;	//41
		public String Zone;	//Musaffah
		public String SectorArabic;	//مصفح غرب 4
		public String ZoneArabic;	//مصفح
		public String SubServiceName;	//Work Permit type
		public String SubServiceValue;	//Request for installation permission of tent within the plot limits
		public String UserId;	//PUBLICUSER463
		public String SubServiceValueArabic;	//
		public String ApplicationSubType;
		public String ApplicationSubTypeAr;
	}
	public class cls_ApplicationSubType {
	}
	public class cls_ApplicationSubTypeAr {
	}
	public class cls_BuildingDetails {
        public String RecordId;	 
		public String BuildingNumber;	 
		public String NumberOfUnits;	 
		public String NumberOfFloors;	 
		public String NumberOfBasementFloors;	 
		public String TotalHeight;	 
		public String BuildingArea;	
		public String FloorArea;	 
		public String NumberOfEntrances; 
		public String RecordUpdatedDate;
        public String RecordDate;
	}
	 public class cls_Documents {
        public String DocumentId;	 
		public String RecordId;	 
		public String DocumentName;	 
		public String DocumentGroup;	 
		public String DocumentDescription;	 
		public String DocumentType;	 
		public String DocumentCategory;	
		public String FileName;	 
		public Decimal FileSize; 
		public String UploadDate;
        public String RecordDate;
	}
	Public class cls_Fees {
		public String RecordId;	 
		public Decimal FeeId;	 
		public String FeeDescription;	 
		public Decimal FeeAmount;	 
		public Decimal FeeCount;	 
		public Decimal FeeTotal;	 
		public String FeeApplyDate;	
		public String FeeStatus;	 
		public String FeeSchedule; 
		public String StatusDate;
        public Decimal INVOICE_NUMBER;
        public String AUTO_INVOICED;
        public Decimal INVOICE_BALANCE_DUE;
        public Decimal INVOICE_AMOUNT;
        public String INVOICE_DATE;
	}
	 public class cls_Inspections {
		public String RecordId;	 
		public Decimal InspectionNumber;	
		public String InspectionType;	 
		public String Inspector;	 
		public String ScheduleDate;	 
		public String InspectionDate; 
		public String InspectionStatus;	 
		public String InspectorComments;
		public String RecordDate;
        public String UserId;
        public String Department;
	}
	public class cls_InspectorComments {
	}
	public class cls_Parcels {
		public String GisID;	 
		public String Zone;
		public String PlotArea;
		public String Sector;
		public String Street;
		public String LandUse;
		public String LandUseArabic;
		public String LandUseIdentifier;
		public String Municipality;
		public String PlotNumber;
		public String PlotWidth;
		public String SecondaryLandUse;
		public String SecondaryLandUseArabic;
		public String SitePlanNumber;
		public String StatusDate;	 
		public String RecordId;
	}
	class cls_Zone {
	}
	class cls_PlotArea {
	}
	class cls_Sector {
	}
	class cls_Street {
	}
	class cls_LandUse {
	}
	class cls_LandUseArabic {
	}
	class cls_LandUseIdentifier {
	}
	class cls_Municipality {
	}
	class cls_PlotNumber {
	}
	class cls_PlotWidth {
	}
	class cls_SecondaryLandUse {
	}
	class cls_SecondaryLandUseArabic {
	}
	class cls_SitePlanNumber {
	}
	class cls_RecordId {
	}
	Public class cls_Permits {
		public String RecordId;	//B1S-2022-000021-WKT03
		public String Municipality;	//DAR
		public String ServiceName;	//Work Permit Request
		public String ServiceNameArabic;	//طلب تصريح أعمال
		public String ServiceCode;	//WRKP
		public String CurrentRecordStatus;	//Submitted
		public String CurrentKPIStatusOfRecord;
		public String KPIStartDate;	//2023-01-04 08:49:22.327
		public String KPIEndDate;	//null
		public Decimal KPIAchievedInDays;	//114
		public String SubmissionDate;	//2023-01-04 00:00:00.0
		public String GisID;	//10004139700
		public String KPIEndStatusType;
		public String KPIStartStatus;
		public String KPIEndStatus;
		public String CreatedBy;
		public String channel;	//TAMM
		public String LastStatusDate;	//2023-01-04 08:48:05.577
        public String HappinessFeedback;
        public String HappinessComment;
        public String SubServiceValue;
        public String SubServiceValueArabic;
        public String TransactionCode;
        public String PaymentStatus;
        public String PaymentAmount;
        public String PaymentDate;
	}
	class cls_CurrentKPIStatusOfRecord {
	}
	class cls_KPIEndStatusType {
	}
	class cls_KPIStartStatus {
	}
	class cls_KPIEndStatus {
	}
	class cls_CreatedBy {
	}
	Public class cls_PermitsCustomProperties {
		public String RecordId;	//M1-2023-000008
		public String ASIFieldName;	//Entity Name Arabic
		public String ASIFieldValue;	//شرطة ابوظبي
		public String ASIFieldGroup;	//REQUEST DETAILS
		public String RecordDate;	//2023-01-04 00:08:02.347
	}
	Public class cls_Professionals {
		public String RecordId;	//B1M-2022-007188-P02-C01-INS02
		public String ConsultantTradeLicenseNumber;	//CN-1001312
		public String ConsultantType;	//Designer and Supervisor
		public String ConsultantName;	//BEIRUT ENGINEERING CONSULTING BUREAU- ABUDHABI
		public String ConsultantEmail;	//oahmad@c.com
		public String ConsultantMobile;	//-
		public String ContractorName;	//TRUST CONTRACTING &AMP; GENERAL MAINTENANCE L.L.C.
		public String ContractorMobile;	//0562820330
		public String ContractorTradeLicenseNumber;	//CN-1006257
		public String ContractorEmail;	//oahmad@D.com
		public String StatusDate;	//2023-01-04 00:00:00.0
	}
	Public class cls_StatusHistory {
		public String RecordId;	//B1S-2022-000021-WKT03
		public String RecordStatus;	//Submitted
		public Integer StatusHistoryId;	//821683
		public String StatusDate;	//2023-01-04 08:48:05.577
		public String StatusComment;
		public String ServiceCode;	//WRKP
	}
	Public class cls_StatusComment {
	}
	Public class cls_WorkflowTasks {
		public String RecordId;	//M1-2023-000008
		public String TaskName;	//Review Transaction
		public String TaskStatus;
		public String DueDays;	//0
		public String DueDate;	//2023-09-14 00:00:00.0
		public String AssginedDate;	//2023-09-14 00:00:00.0
		public String StatusDate;	//2023-01-04 00:08:02.347
		public String KPIInDays;	//0
		public String IsActive;	//Y
		public String IsCompleted;	//N
		public String Comments;
		public String Department;	//NA
		public String EmployeeName;
		public String EmployeeId;	//PUBLICUSER1246
		public Integer SequenceId;	//13005
	}
	class cls_TaskStatus {
	}
	class cls_Comments {
	}
	class cls_EmployeeName {
	}
	Public class cls_WorkflowHistory {
		public String RecordId;	//B1M-2022-005582-P01-C01-CD01
		public String TaskName;	//Fast Track Payment
		public String TaskStatus;	//No Payment Required
		public String DueInDays;	//null
		public String TaskDueDate;	//2023-06-02 00:00:00.0
		public String TaskAssignedDate;	//2023-06-02 00:00:00.0
		public String TaskStatusDate;	//2023-06-02 10:59:32.49
		public Decimal TaskKPIInDays;	//0
		public String IsActive;	//N
		public String IsCompleted;	//Y
		public String Comments;
		public String Department;	//NA
		public String EmployeeName;	//System User
		public String EmployeeId;	//H.JAMOUS
		public Integer Id;	//1780
		public String StatusDate;	//2023-01-04 00:00:00.0
	}
	public static TasareehIntegration_Parser parse(String json){
        System.debug('json deser >>'+json);
		return (TasareehIntegration_Parser) System.JSON.deserialize(json, TasareehIntegration_Parser.class);
	}

}