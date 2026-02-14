import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retrieveUsername from '@salesforce/apex/DMPortalAuthController.retrieveUsername';
//import CUSTOMCSS from '@salesforce/resourceUrl/customInput'; // Import the static resource
import { loadStyle } from 'lightning/platformResourceLoader';



export default class ForgotUsernameModal extends LightningElement {
    @track isModalOpen = false;
    @track emailAddress = '';
    @track isLoading = false;
    @track showResult = false;
    @track resultMessage = '';
    @track isSuccess = false;
    //isCssLoaded = false; // Define a variable to check if CSS is loaded

    @api
    openModal() {
        this.isModalOpen = true;
        this.resetForm();
    }

    // Close modal
    closeModal() {
        this.isModalOpen = false;
        this.resetForm();
    }

    get isSubmitDisabled() {
    return this.isLoading || !this.emailAddress;
    }

    get resultClass() {
        return this.isSuccess 
            ? 'slds-notify slds-notify_toast slds-theme_success' 
            : 'slds-notify slds-notify_toast slds-theme_error';
    }

     // Load the custom CSS when the component is rendered
  /*  renderedCallback() {
        if (this.isCssLoaded) return; // Ensure the CSS is only loaded once

        this.isCssLoaded = true;

        // Load the CSS static resource
        loadStyle(this, CUSTOMCSS)
            .then(() => {
                console.log('CSS loaded successfully');
            })
            .catch((error) => {
                console.log('Error loading CSS:', error);
            });
    }*/

   /* get resultIcon() {
        return this.isSuccess ? 'utility:success' : 'utility:error';
    }*/


    // Reset form state
    resetForm() {
        this.emailAddress = '';
        this.showResult = false;
        this.resultMessage = '';
        this.isSuccess = false;
        this.isLoading = false;
    }

    // Handle email input change
    handleEmailChange(event) {
        this.emailAddress = event.target.value;
        this.showResult = false; // Hide previous results
    }
    

    // Handle form submission
    async handleSubmit() {
        // Client-side validation
        if (!this.validateEmail()) {
            return;
        }

        this.isLoading = true;

        try {
            const result = await retrieveUsername({ email: this.emailAddress });
            this.isSuccess = result.success;
            this.showResult = true;
            console.log('Result from Apex:', result);


            if (result.success) {
              //  this.resultMessage = `Your username is: ${result.username}`;
                this.resultMessage = `An email with your username has been sent to your registered email address. If you're still unable to log in, please reset your password using the "Forgot Your Password" option with your username.`;

            } else {
                this.resultMessage = result.message;
            }
        } catch (error) {
            this.isSuccess = false;
            this.showResult = true;
            this.resultMessage = 'An error occurred. Please try again or contact support.';
            console.error('Error retrieving username:', error);
        } finally {
            this.isLoading = false;
        }
    }
  
    // Client-side email validation
    validateEmail() {
        const emailInput = this.template.querySelector('lightning-input[data-id="email"]');
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!this.emailAddress || !emailRegex.test(this.emailAddress)) {
            emailInput.setCustomValidity('Please enter a valid email address');
            emailInput.reportValidity();
            return false;
        }

        emailInput.setCustomValidity('');
        emailInput.reportValidity();
        return true;
    }

    // Handle ESC key to close modal
    handleKeyDown(event) {
        if (event.keyCode === 27) { // ESC key
            this.closeModal();
        }
    }
}