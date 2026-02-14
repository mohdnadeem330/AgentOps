@isTest
private class DateTimeUtilityTest {
    
    @isTest static  void dateTimeUtility() {

        string dateString = System.now().format();
        List<DateTimeUtility.DateTimeRequest> requests = new List<DateTimeUtility.DateTimeRequest>();
        
        // Date.today
        DateTimeUtility.DateTimeRequest dt1 = new DateTimeUtility.DateTimeRequest();
        dt1.methodName = 'Date.today';
        requests.add(dt1);

        // Datetime null DateTimeUtilityException
        try{
            DateTimeUtility.DateTimeRequest dt2 = new DateTimeUtility.DateTimeRequest();
            dt2.methodName = 'Datetime.addDays';
            DateTimeUtility.methods(new List<DateTimeUtility.DateTimeRequest>{dt2});
        } catch(DateTimeUtility.DateTimeUtilityException e){
            System.assertEquals('Datetime string cannot be null error', e.getMessage());
        }

        Set<String> datetimeMethods = new Set<String>{'Datetime.addDays', 'Datetime.addHours', 'Datetime.addMinutes', 'Datetime.addSeconds', 
        'Datetime.addMonths', 'Datetime.addYears', 'Datetime.formatGmt', 'Datetime.format', 'Datetime.formatLong', 'Datetime.getTime', 'Datetime.hour',
        'Datetime.hourGmt', 'Datetime.millisecond', 'Datetime.millisecondGmt', 'Datetime.minute', 'Datetime.minuteGmt', 'Datetime.month', 'Datetime.monthGmt',
        'Datetime.second', 'Datetime.secondGmt', 'Datetime.time', 'Datetime.timeGmt', 'Datetime.year', 'Datetime.yearGmt', 'Datetime.day', 'Datetime.dayGmt', 
        'Datetime.now', 'BusinessHours.add', 'BusinessHours.addGmt', 'BusinessHours.isWithin', 'BusinessHours.nextStartDate'
    };
        
        for(String method : datetimeMethods){
            DateTimeUtility.DateTimeRequest dt = new DateTimeUtility.DateTimeRequest();
            dt.methodName = method;
            dt.dateTimeString = dateString;
            dt.increment = 1;
            requests.add(dt);
        }

        Set<String> dateMethods = new Set<String>{'Date.addDays', 'Date.addMonths', 'Date.addYears', 'Date.month', 'Date.year', 'Date.toStartOfWeek', 
        'Date.toStartOfMonth', 'Date.day', 'Date.dayOfYear', 'Date.today', 'Date.monthsBetween', 'Date.isLeapYear', 'Date.daysInMonth', 'Date.daysBetween'
        };
        
        for(String method : dateMethods){
            DateTimeUtility.DateTimeRequest dt = new DateTimeUtility.DateTimeRequest();
            dt.methodName = method;
            dt.dateTimeString = System.today().format();
            dt.increment = 1;
            if('Date.monthsBetween' == method || 'Date.daysBetween' == method){
                dt.secondDateString = System.today().format(); 
            }
            requests.add(dt);
        }

        DateTimeUtility.DateTimeRequest dd1 = new DateTimeUtility.DateTimeRequest();
        dd1.methodName = 'Date.addDays';
        dd1.dateTimeString = System.today().format();
        dd1.increment = 1;
        requests.add(dd1);

        // BusinessHours.diff
        try{
            DateTimeUtility.DateTimeRequest dt3 = new DateTimeUtility.DateTimeRequest();
            dt3.methodName = 'BusinessHours.diff';
            dt3.dateTimeString = System.now().format();
            dt3.increment = 1;
            dt3.secondDateString = System.now().format(); 
            DateTimeUtility.methods(new List<DateTimeUtility.DateTimeRequest>{dt3});
            dt3.secondDateString = null; 
            DateTimeUtility.methods(new List<DateTimeUtility.DateTimeRequest>{dt3});
            dd1.businessHoursName = 'wronge business hour';

        } catch(DateTimeUtility.DateTimeUtilityException e){
            System.assertEquals('Diff method requires secondDateString error', e.getMessage());
        }

        // wronge business hour
        try{
            DateTimeUtility.DateTimeRequest dt3 = new DateTimeUtility.DateTimeRequest();
            dt3.methodName = 'BusinessHours.add';
            dt3.dateTimeString = System.now().format();
            dt3.increment = 1;
            dt3.businessHoursName = 'wronge business hour';
            DateTimeUtility.methods(new List<DateTimeUtility.DateTimeRequest>{dt3});

        } catch(DateTimeUtility.DateTimeUtilityException e){
            System.assertEquals('No default business hours set error', e.getMessage());
        }

        // wronge method name
        try{
            DateTimeUtility.DateTimeRequest dt3 = new DateTimeUtility.DateTimeRequest();
            dt3.methodName = 'BusinessHours.addWronge';
            dt3.dateTimeString = System.now().format();
            dt3.increment = 1;
            dt3.businessHoursName = 'wronge business hour';
            DateTimeUtility.methods(new List<DateTimeUtility.DateTimeRequest>{dt3});

        } catch(DateTimeUtility.DateTimeUtilityException e){
        }
        DateTimeUtility.methods(requests);

    }
}