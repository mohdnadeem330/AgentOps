@isTest
public class ECSS_PhoneNumberValidityTest {
    
    @isTest
    public static void validate(){
        String mobileNumber = '01062156646';
        String Countrycode= '20';
        
        
        ECSS_PhoneNumberValidity.Validate(mobileNumber, Countrycode);
        
        String mobileNumber1 = '01062156646';
        String Countrycode1='+960';
        
        ECSS_PhoneNumberValidity.Validate(mobileNumber1, Countrycode1);
        
        String mobileNumber2 = '01062156646';
        String Countrycode2='1';
        
        ECSS_PhoneNumberValidity.Validate(mobileNumber2, Countrycode2);
        
    }
    
    
    @isTest
    public static void format(){
        String mobileNumber = '01062156646';
        String Countrycode= '20';
        
        
        ECSS_PhoneNumberValidity.format(mobileNumber, Countrycode);
        
        String mobileNumber1 = '01062156646';
        String Countrycode1= '1';
        
        
        ECSS_PhoneNumberValidity.format(mobileNumber1, Countrycode1);
        
        
        
    }
    
    
}