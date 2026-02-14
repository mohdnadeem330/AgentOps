global with sharing class DuplicateAccountResponseWrapper {
    public DupAcc DuplicateResponse;
    //public LeadVerifyResponse leadVerifyResponse;
    public class DupAcc{
        public Boolean isEmailValid;
        public Boolean isPhoneValid;
        public Boolean hasDuplicates;
        public Boolean hasCompleted;
        public String selectedAccountId;
        public boolean exceptionApprovalStatus;
        public String exceptionApprovalReason;
        public List<DuplicateAcc> DuplicateAccounts;
        public Boolean isVerifiedByEmail;
        public DupAcc(Boolean ev,Boolean pv,Boolean hd,Boolean hc,String sa,Boolean ea,Boolean isve,String ear){
            this.isEmailValid=eV;
            this.isPhoneValid=pV;
            this.hasDuplicates=hd;
            this.hasCompleted = hc;
            this.selectedAccountId = sa;
            this.exceptionApprovalStatus = ea;
            this.exceptionApprovalReason = ear;
            this.isVerifiedByEmail = isve;
        }
        
    }
    public class DuplicateAcc{
        public String Name;
        public String AccountNumber;
        public Decimal SalesOrderCount;
        public String CustomerType;
        public String CustomerSubType;
        public String PassportNumber;
        public String KYCValidity;
        public String EmiratesId;
        public String ResidentStatus;
        public String AccountId;

    }
}