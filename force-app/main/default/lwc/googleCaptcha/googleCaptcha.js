import { LightningElement } from 'lwc';

export default class GoogleCaptcha extends LightningElement {

    connectedCallback() {

        document.addEventListener( "grecaptchaVerified", ( e ) => {

            let detailPayload = { value : false, response : e.detail.response };
            this.dispatchEvent( new CustomEvent( 'captcha', { detail : detailPayload } ) );

        });

        document.addEventListener( "grecaptchaExpired", () => {

            this.dispatchEvent( new CustomEvent( 'captcha', { detail : { value : true } } ) );

        } );
        
    }

    renderedCallback() {

        let divElement = this.template.querySelector( 'div.recaptchaCheckbox' );
        let payload = { element: divElement };
        document.dispatchEvent(new CustomEvent( "grecaptchaRender", { "detail": payload } ) );
        
    }

}