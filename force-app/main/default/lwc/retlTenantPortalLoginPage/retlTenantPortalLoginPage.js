import { LightningElement } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages";
// import tenantPortalLogin from '@salesforce/apex/RETL_TenantLoginPageController.login';

export default class retlTenantPortalLoginPage extends LightningElement {
    
    ysmimage = Images + '/Login-Page/ysm1.png';
    Logo = Images + '/Login-Page/liv aldar logo.png';
    ikon = Images + '/Login-Page/eye.png';
    get backgroundStyle() {
        return `background-image: url(${this.ysmimage});`;
    }

    username;
    password;
    errorMessage;
    hasError = false;
    //handleChange
    handleChange(event){
        console.log('handleChange');
        const field = event.target.dataset.id;
        if (field === 'email') {
            this.email = event.target.value;
        } else if (field === 'password') {
            this.password = event.target.value;
        }
    }

    //login-button
    handleLogin(){
        this.starturl = '/tenant';
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
            /*tenantPortalLogin({ username: this.email, password: this.password, startUrl: this.starturl })
                .then((result) => {
                    window.location.href = result;
                })
                .catch(error => {
                    this.error = 'Invalid email or password. Please try again.';
                    console.error(error);
            })
            .catch((error) => {
                        console.log(error);
                        console.log(JSON.stringify(error))
                        this.hasError = true;
                        this.errorMessage = error.body.message;
            }); */
        }
        catch(e){
            console.log(e.message)
        }
    }

}