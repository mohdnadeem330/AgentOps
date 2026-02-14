/**
 * @description       : This class used for handle Custom Permission for LSQ.
 * @author            : nmehra@aldar.com
 * @group             : LSQ
 * @last modified on  : 08/01/2026
 * @last modified by  : nmehra@aldar.com
 * Modifications Log
 * Ver   Date         Author                 Modification 
 * 1.0   08/01/2026   nmehra@aldar.com          LAS-61   
 **/
public class LSQ_UserValidation {
    public static Boolean isLsqUser() {
        return FeatureManagement.checkPermission('LSQ_Custom_Permission') || FeatureManagement.checkPermission('LSQ_Custom_Permission_Aldar');
    }
}