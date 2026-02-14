global class ECSS_PhoneNumberValidity {
   global static boolean Validate(String MobilePhone , String MobileCountry ) {
        system.debug('MobilePhone' + MobilePhone);
        MobilePhone = MobilePhone.replace(' ', '');
        MobilePhone = MobilePhone.replace('-', '');
        MobilePhone = MobilePhone.replace('.', '');
        MobilePhone = MobilePhone.replace('_', '');
        MobilePhone = MobilePhone.replace('(', '');
        MobilePhone = MobilePhone.replace(')', '');
        MobilePhone = MobilePhone.replace('/', '');
       system.debug('MobileCountry' + MobileCountry);
        if ( String.isNotEmpty(MobileCountry) ) {
            if(MobileCountry =='Canada (+1)'){
                MobileCountry = '+1';
            }
       if (MobileCountry =='+960')
            {
                Pattern maldivesPhonePattern = Pattern.compile('^\\+960\\d{7}$');
                Matcher matcher = maldivesPhonePattern.matcher(MobilePhone);
                system.debug(matcher.matches());
                if (!matcher.matches()) {
                return false;
            }
                else
                {
                    return true;
                }
            }
            else
         {
           Phone_Number_Info__mdt info = Phone_Number_Info__mdt.getInstance('X'+MobileCountry.right(MobileCountry.length()));
             String regex = String.valueOf(info.Regex__c);
            system.debug('regex' + regex);
            Pattern regexPattern = Pattern.compile(regex);
            system.debug('regexPattern' + regexPattern);
            Matcher regexMatcher = regexPattern.matcher(MobilePhone);
            system.debug('regexMatcher' + regexMatcher);
            system.debug(regexMatcher.matches());
            if (!regexMatcher.matches()) {
                return false;
            }
            }
        }
        else {
            throw new IllegalArgumentException('MobileCountry is required.');
        }
        return true;
   }
    global static String format(String MobilePhone , String MobileCountry ) {
        MobilePhone = MobilePhone.replace(' ', '');
        MobilePhone = MobilePhone.replace('-', '');
        MobilePhone = MobilePhone.replace('.', '');
        MobilePhone = MobilePhone.replace('_', '');
        MobilePhone = MobilePhone.replace('(', '');
        MobilePhone = MobilePhone.replace(')', '');
        MobilePhone = MobilePhone.replace('/', '');

        if(MobileCountry =='Canada (+1)'){
            MobileCountry = '+1';
        }
        Phone_Number_Info__mdt info = Phone_Number_Info__mdt.getInstance('X'+MobileCountry.right(MobileCountry.length()));
        if (MobilePhone.length() < info.Phone_Length__c  &&
            MobilePhone.length() >= info.Phone_Length__c - MobileCountry.length() &&
            ! MobilePhone.contains(MobileCountry)
           ){
               MobilePhone=String.valueOf(MobileCountry)+MobilePhone.right(info.Phone_Length__c.intValue() - String.valueOf(MobileCountry).length());
           }
        return MobilePhone;
    }

}