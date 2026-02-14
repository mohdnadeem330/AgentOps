import { LightningElement, track } from 'lwc';
import doLogin from '@salesforce/apex/DM_CommunityAuthCtrl.doLogin';
import HomeImages from "@salesforce/resourceUrl/HomeImages";
import { loadStyle } from 'lightning/platformResourceLoader';
import ExternalStyle from "@salesforce/resourceUrl/ExternalStyle";
import verifyOTP from '@salesforce/apex/DM_CommunityAuthCtrl.verifyOTP';
import sendOTP from '@salesforce/apex/DM_CommunityAuthCtrl.sendSMSMFAlogin';


export default class Retl_CustomLogin extends LightningElement {
    renderedCallback() {
        Promise.all([
            loadStyle(this, ExternalStyle)
        ])
    }
    Logo = HomeImages + '/Home-Images/DM_logo_login.png';
    Loginbg = HomeImages + '/Home-Images/DM_bg_image.png';
    Mailnew = HomeImages + '/Home-Images/DM_mail2.svg';
    Thumb = HomeImages + '/Home-Images/DM_thumb.svg';


    registrationURL = '/SelfRegister';
    forgotUrl = '/ForgotPassword';
    username;
    password;
    hasError = false;
    errorMessage;
    showLogin = true;
    otpScreen = false;
    refreshCounter;
    mobileInterval;
    counter = 1;
    showCounter = false;
    OTP;
    starturl;
    otpSentMsg;
    emailWarningShown = false; // Track if warning was already shown
    showCustomToast = false; // Control custom toast visibility
    toastMessage = ''; // Store toast message
    toastTitle = ''; // Store toast title
    toastVariant = ''; // Store toast variant

    handleChange(event) {
        if (event.target.name === 'username') {
            this.username = event.target.value;

            // Modified by Neelesh - Show custom toast instead of message
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            const domainAllowed = '@aldar.com.dm';

            if (emailRegex.test(this.username) && !this.username.includes(domainAllowed)) {
                // Show custom toast warning only once per session
                if (!this.emailWarningShown) {
                    this.showCustomToastMessage('', 'This appears to be your Email Address. Please use your Username to login. If you\'ve forgotten the Username, click \'Forgot your username?\' below.', 'warning');
                    this.emailWarningShown = true;
                }
            } else {
                // Reset the warning flag if user corrects the input
                this.emailWarningShown = false;
                this.hideCustomToast();
            }
            // End Modified by Neelesh
        }

        if (event.target.name === 'password') {
            this.password = event.target.value;
        }
    }

    // Custom toast methods for Experience Cloud
    showCustomToastMessage(title, message, variant) {
       // this.toastTitle = title;
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showCustomToast = true;

        // Auto-hide after 5 seconds
        setTimeout(() => {
            this.hideCustomToast();
        }, 30000);
    }

    hideCustomToast() {
        this.showCustomToast = false;
    }

    // Get CSS classes for toast styling
    get toastClasses() {
        const baseClasses = 'slds-notify slds-notify_toast slds-theme_';
        switch(this.toastVariant) {
            case 'success':
                return baseClasses + 'success';
            case 'warning':
                return baseClasses + 'warning';
            case 'error':
                return baseClasses + 'error';
            default:
                return baseClasses + 'info';
        }
    }

    // Get icon name for toast
    get toastIcon() {
        switch(this.toastVariant) {
            case 'success':
                return 'utility:success';
            case 'warning':
                return 'utility:warning';
            case 'error':
                return 'utility:error';
            default:
                return 'utility:info';
        }
    }
    get toastTypeClass() {
    switch(this.toastType) {
        case 'success':
            return 'toast-success';
        case 'error':
            return 'toast-error';
        case 'warning':
            return 'toast-warning';
        case 'info':
            return 'toast-info';
        default:
            return 'toast-info';
    }
}

    keyCodeHandler(component, event, helper) {
        if (component.which == 13) {
            this.handleLogin();
        }
    }

    handleLogin(event) {
        this.starturl = '/business';
        try {
            const queryString = window.location.search;
            const urlParams = new URLSearchParams(queryString);

            if (urlParams.get('startURL')) {
                this.starturl = urlParams.get('startURL');
            }

            const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputField) => {
                    inputField.reportValidity();
                    return validSoFar && inputField.checkValidity();
                }, true);

            if (isInputsCorrect) {
                doLogin({ username: this.username, password: this.password, startUrl: this.starturl })
                    .then((result) => {
                        if (result.includes('http'))
                            window.location.href = result;
                        if (result.includes('OTP sent')) {
                            this.otpSentMsg = result;
                            this.hasError=false;
                            this.showLogin = false;
                            this.otpScreen = true;
                            this.showCounter = true;
                            this.mobileInterval = setInterval(function () {
                                if (this.refreshCounter == 1) {
                                    this.counter = 1;
                                    this.refreshCounter = 0;
                                    this.showCounter = false;
                                    clearInterval(this.mobileInterval);
                                }
                                this.refreshCounter = 60 - (this.counter++);
                            }.bind(this), 1000);
                        }

                    })
                    .catch((error) => {
                        console.log(error);
                        console.log(JSON.stringify(error))
                        this.hasError = true;
                        this.errorMessage = error.body.message;

                    });
            }
        } catch (e) {
            console.log(e.message)
        }
    }

    openEmail() {
        window.location.href = 'mailto:dcportalsupport@aldar.com';
    }
    verifyOtp(event) {
        const input = this.template.querySelector('[autocomplete=one-time-code');
        this.OTP = input.value;
        verifyOTP({ username: this.username, password: this.password, startUrl: this.starturl, otp: this.OTP }).then(res => {
            if (res) {
                if (res.includes('http'))
                    window.location.href = res;
                if (res.includes('WrongOTP')) {
                    const input = this.template.querySelector('[autocomplete=one-time-code');
                    input.value = '';
                    this.hasError = true;
                    this.errorMessage = 'OTP you have entered is incorrect';
                }

            }
        }).catch(err => {
            console.log('err-verifyOtp->', err);
            this.hasError = true;
            this.errorMessage = 'OTP you have entered is incorrect';
        })
    }
     /* Added to open Forgot Username Modal by Neelesh  */
    openForgotUsernameModal() {
        const modal = this.template.querySelector('c-dm-forgot-username-modal');
        if (modal) {
            modal.openModal();
        }
    }
    // Added to open Forgot Password Modal by Neelesh  */
    sendOtp() {
        this.OTP = null;
        const input = this.template.querySelector('[autocomplete=one-time-code');
        input.value = '';
        this.hasError = false;
        sendOTP({ username: this.username }).then(res => {
            if (res.includes('OTP sent')) {
                this.otpSentMsg = res;
                this.showLogin = false;
                this.otpScreen = true;
                this.showCounter = true;
                this.mobileInterval = setInterval(function () {
                    if (this.refreshCounter == 1) {
                        this.counter = 1;
                        this.refreshCounter = 0;
                        this.showCounter = false;
                        clearInterval(this.mobileInterval);
                    }
                    this.refreshCounter = 60 - (this.counter++);
                }.bind(this), 1000);
            } else {
                this.hasError = true;
                this.errorMessage = 'Unable to send OTP';
            }
        }).catch(err => {
            console.log('err-sendOTP->', err);
            this.hasError = true;
            this.errorMessage = 'Unable to send OTP';
        });
    }
    get ringCounters() {
        return (100 / 90) * this.refreshCounter;
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
}