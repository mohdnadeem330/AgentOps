import { LightningElement, track, wire } from 'lwc';
import basePath from '@salesforce/community/basePath';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import doLogin from '@salesforce/apex/CommunityAuthController.doLogin';
import forgotPassowrd from '@salesforce/apex/CommunityAuthController.forgotPassowrd';
import verifyOTP from '@salesforce/apex/CommunityAuthController.verifyOTP';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import BrokerAgencyRegistrationURL from '@salesforce/label/c.BrokerAgencyRegistrationURL';
import fetchOTPExpiryTime from '@salesforce/apex/CommunityAuthController.getBrokerOTPTimer';
import resendOTPEmail from '@salesforce/apex/CommunityAuthController.sendEmailMFAlogin';
import FORM_FACTOR from '@salesforce/client/formFactor';
import AldarExpertsAndroidLink from '@salesforce/label/c.AldarExpertsAndroidLink';
import AldarExpertsiOSLink from '@salesforce/label/c.AldarExpertsiOSLink';
import { NavigationMixin } from 'lightning/navigation';

export default class CustomLogin extends NavigationMixin(LightningElement) {

    showLoginForm           =   true;
    showEnterOTPForm        =   false;
    showForgotPasswordForm  =   false;
    showSpinner             =   false;
    errorMessageWrongOTP;
    errorCheckWrongOTP      =   false;
    showResendOTPButton     =   false;
    showCountDownTimer      =   true;
    otpSentEmailAddress;
    refreshCounter;
    countDownTimerInMin;
    countDownTimerInSeconds;
    counter = 1;
    aldarlogo   = resourcesPath+ "/ALDARResources/png/AldarLogo.png";
    lsqlogo     = resourcesPath+ "/ALDARResources/png/lsqLogo.png";
    sodiclogo   = resourcesPath+ "/ALDARResources/png/sodicLogo.png";
    error;
    errorCheck=false;
    errorMessage;
    errorForgotPassword;
    errorCheckForgotPassword=false;
    errorMessageForgotPassword;
    successCheckForgotPassword=false;
    successMessageForgotPassword;
    username = '';
    password = '';
    errorMessageWrongOTP;
    errorCheckWrongOTP = false;
    otpSentEmailAddress;
    @track disableButton = false;
    registrationURL = BrokerAgencyRegistrationURL;

    deviceFormFactor = FORM_FACTOR;
    aldarExpertsiOSLink = AldarExpertsiOSLink;
    aldarExpertsAndroidLink = AldarExpertsAndroidLink;

    get isDesktop() {
        return this.deviceFormFactor === 'Large';
    }
    get openAndriod() {
        return this.detectPlatform().isAndroid;
    }
    get openIOS() {
        return this.detectPlatform().isIOS;
    }

    // openAppURL() {
    //     const userAgent = window.navigator.userAgent;

    //     const { isIOS, isAndroid } = this.detectPlatform();

    //     if (isAndroid) {
    //          //window.open(AldarExpertsAndroidLink);
    //         this[NavigationMixin.Navigate]({
    //             type: 'standard__webPage',
    //             attributes: {
    //                 url: AldarExpertsAndroidLink
    //             }
    //         }, true);
    //      }else if(isIOS){
    //         //this.openIOS = true;
    //         //window.open(AldarExpertsiOSLink);
    //         //  this[NavigationMixin.Navigate]({
    //         //      type: 'standard__webPage',
    //         //      attributes: {
    //         //          url: AldarExpertsiOSLink
    //         //      }
    //         //  }, true);
    //     }
    // }

    detectPlatform() {
        const ua = navigator.userAgent || '';
        const isAndroid = /android/i.test(ua);
        // iPadOS 13+ may say "Macintosh"; check for touch capability
        const isiOSUA = /iPad|iPhone|iPod/.test(ua);
        const isIPadMac = ua.includes('Macintosh') && 'ontouchend' in document;
        const isIOS = isiOSUA || isIPadMac;
        return { isIOS, isAndroid };
    }

    showHideForgotPasswordForm(){
           this.showLoginForm           =   !this.showLoginForm;
           this.showForgotPasswordForm  =   !this.showForgotPasswordForm;
    }

    showHideEnterOTPForm(){
        this.showLoginForm              =   !this.showLoginForm;
        this.showEnterOTPForm           =   !this.showEnterOTPForm
    }

    @wire(fetchOTPExpiryTime)
    wiredData({ error, data }) {
        if (data) {
            this.countDownTimerInMin        = data.Timer__c;
            this.countDownTimerInSeconds    = this.countDownTimerInMin * 60;
        } else if (error) {
            console.error('Error:', error);
        }
    }
    

    handleEmailValidation() {
        var flag = true;
        const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        let email = this.template.querySelector('[data-id="txtEmailAddress"]');
        let emailVal = email.value.trim(' ');
        if (emailVal.match(emailRegex)) {
            email.setCustomValidity("");

        } else {
            flag = false;
            email.setCustomValidity("Please enter a valid email");
        }
        email.reportValidity();
        return flag;
    }

    keyCheck(event){
        if (event.which == 13){
            this.handleLogin(event);
        }
    }

    keyCheckForgetPassword(event){
        if (event.which == 13){
            this.handleForgetPassword();
        }
    }

    handleForgetPassword(){

        let email = this.template.querySelector('[data-id="txtForgetPasswordEmailAddress"]');
        let emailVal = email.value.trim(' ');
        // console.log('emailVal' + emailVal);
        forgotPassowrd({userid : emailVal})
            .then((result) => {
                console.log('handleForgetPassword'+result); 
                this.errorCheckForgotPassword = false;
                this.successCheckForgotPassword = true;
                this.successMessageForgotPassword = 'Reset password link is sent to your registered email address';
                setTimeout(() => {
                    this.showHideForgotPasswordForm();
                }, 5000);
            })
            .catch((error) => {
                this.errorForgotPassword = error;
                this.successCheckForgotPassword = false;
                this.errorCheckForgotPassword = true;
                this.errorMessageForgotPassword = 'Forget password reset email sending failed, make sure you entered correct username';
            });
    }

    keyVerifyEnteredOTP(event){
        if (event.which == 13){
            this.handleVerifyEnteredOTP();
        }
    }

    /* Added by Tharun BPE-108 */
    handleVerifyEnteredOTP(event){
        this.showSpinner    = true;
        let otp             = this.template.querySelector('[data-id="txtEnteredOTP"]');
        let otpVal          = otp.value.trim(' ');

        verifyOTP({
            username    :   this.username, 
            otpEntered  :   otpVal,
            password    :   this.password,
            startUrl    :   '/'
        }).then(result => {
            console.log('handleVerifyEnteredOTP result' + JSON.stringify(result));
            this.showSpinner    = false;
            if(result.Success != null && result.Success){
                window.location.href = result.Success
            }else if(result.Failed != null && result.Failed){
                console.log('Result >>>'+ result.Failed);
                this.errorMessageWrongOTP = result.Failed;
                this.errorCheckWrongOTP = true;
            }
        }).catch(error => {
            console.log('error verify OTP----',error);
            this.showSpinner    = false;
            let errorMsg        = JSON.stringify(error);
            errorCheckWrongOTP = true;
            if(error.body.message!=undefined && error.body.message!='' && error.body.message!=null) {
                this.errorMsg = error.body.message;
                this.errorMessageWrongOTP = errorMsg;
            }
        });
    }

    /* Handle Resending OTP Added by Tharun BPE-108 */
    handleResendOTP()
    {
        this.showSpinner = true;
        this.errorCheckWrongOTP = false;
        this.template.querySelector('[data-id="txtEnteredOTP"]').value = '';
        resendOTPEmail({username : this.username})
        .then(result => {
            console.log('handle resend OTP result--'+result);
            if(result && result.includes("-") && result.includes("OTPSent")){
                this.showSpinner = false;
                var resArray = result.split("-");
                this.otpSentEmailAddress = resArray[1];
                this.showCountDownTimer = true;
                var interval=setInterval(function() {
                    if(this.refreshCounter==1){
                        this.counter                    = 1;
                        this.refreshCounter             = 0;
                        this.showCountDownTimer         = false;
                        this.showResendOTPButton        = true;
                        clearInterval(interval);
                    }
                    this.refreshCounter = this.countDownTimerInSeconds - (this.counter++);
                }.bind(this), 1000);
            }
        })
        .catch(error => {
            console.log('ERROR - RESEND OTP -',error);
            this.showSpinner    = false;
            let errorMsg        = JSON.stringify(error);
            errorCheckWrongOTP  = true;
            if(error.body.message!=undefined && error.body.message!='' && error.body.message!=null) {
                this.errorMsg = error.body.message;
            }
        });
    }
    /* Handle Resending OTP Added by Tharun BPE-108 */

    get ringCounter() {
        return (100 / 30) * this.refreshCounter;
    }

    get ringVariant() {
        if (this.refreshCounter < 3) {
            return 'expired'
        }
        if (this.refreshCounter < 10) {
            return 'warning'
        }
        return 'base';
    }
    /* Added by Tharun BPE-108 */

    handleLogin(event){
        this.template.querySelector(".loader").getElementsByClassName.display = "block";
        this.disableButton = true;
        console.log('handleLogin Function');
        if(this.handleEmailValidation()){
            this.showSpinner = true;
            let emailValue = this.template.querySelector('[data-id="txtEmailAddress"]');
            let passwordValue = this.template.querySelector('[data-id="txtPassword"]');
            this.username = emailValue.value.trim(' ');
            this.password = passwordValue.value;;
            // console.log(this.username);
            // console.log(this.password);

            if(this.username && this.password){
            console.log('handleLogin1');
            console.log('-window-'+window.location.search);
            console.log('-document-'+document.location);

            (new URL(document.location)).searchParams.forEach(
            (value, key) => {
                if(key=="startUrl" || key=="startURL") {
                    console.log("*** startURL is " , value);
                }
            });
                
            doLogin({ username: this.username, password: this.password,startUrl: '/' })
                .then((result) => {
                    console.log('handleLogin result'+result);
                    this.showSpinner = false;
                    if(result && result.includes("-") && result.includes("OTPSent")){
                        var resArray = result.split("-");
                        this.otpSentEmailAddress = resArray[1];
                        this.showLoginForm = false;
                        this.showEnterOTPForm = true;

                        var interval=setInterval(function() {
                            if(this.refreshCounter==1)
                            {
                                this.counter                    = 1;
                                this.refreshCounter             = 0;
                                this.showCountDownTimer         = false;
                                this.showResendOTPButton        = true;
                                clearInterval(interval);
                            }
                            this.refreshCounter = this.countDownTimerInSeconds - (this.counter++);
                        }.bind(this), 1000);



                    }else{
                        this.showSpinner = false;
                        window.location.href = result;
                    }
                })
                .catch((error) => {
                    this.showSpinner = false;
                    console.log('KP',error);
                    this.error = error;      
                    this.errorCheck = true;
                    this.errorMessage = error.body.message;
                    this.template.querySelector(".loader").getElementsByClassName.display = "none";
                });
            
            }
        }
         this.disableButton = false;
     };

     showToast(title, message, varaint) {
        console.log('Inside Show Toast...');
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: varaint
        });
        this.dispatchEvent(event);
    }
     
}