@isTest
public class ALD_HomeFinanceCaseReqWrapperTest 
{
	static testMethod void testParse() 
    {
		String json = '{'+
		'  \"firstName\": \"tharun\",'+
		'  \"lastName\": \"kumar HF\",'+
		'  \"mobileCountryCode\": \"971\",'+
		'  \"mobileNumber\": \"0988665\",'+
		'  \"email\": \"tharun@gmail.com\",'+
		'  \"nationality\": \"India\",'+
		'  \"residency\": \"India\",'+
		'  \"city\": \"Hyd\",'+
		'  \"employmentStatus\": \"Salaried/Employed\",'+
		'  \"propertyType\": \"Off-Plan by Aldar\",'+
		'  \"approxPropertyValue\": \"20000\",'+
		'  \"approxLoanAmountRequired\": \"5000\",'+
		'  \"anyOtherInfo\": \"A sample HF case\"'+
		'}';
        
		ALD_HomeFinanceCaseReqWrapper obj = ALD_HomeFinanceCaseReqWrapper.parse(json);
		System.assert(obj != null);
	}
	
}