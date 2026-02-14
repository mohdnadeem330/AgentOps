global class ALD_HomeFinanceCaseReqWrapper 
{
    public String firstName;	//tharun
	public String lastName;	//kumar
	public String mobileCountryCode;	//
	public String mobileNumber;	//
	public String email;	//
	public String nationality;	//
	public String residency;	//
	public String city;	//
	public String employmentStatus;	//
	public String propertyType;	//
	public String approxPropertyValue;	//
	public String approxLoanAmountRequired;	//
	public String anyOtherInfo; //
    
    public static ALD_HomeFinanceCaseReqWrapper parse(String json){
		return (ALD_HomeFinanceCaseReqWrapper) System.JSON.deserialize(json, ALD_HomeFinanceCaseReqWrapper.class);
	}
	
	
}