import { api, LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
export default class DetailsForUpdatesForYou extends LightningElement {


  calendarIcon = resourcesPath + "/ALDARResources/svg/CalendarIcon.svg";
  downloadIcon = resourcesPath + "/ALDARResources/svg/DownloadIcon.svg";

  @api parentScreenName;



  @api startFrom;



  arrayLength = 0;

  currentPage=0
  slideIndex = 1;


  @api array;

@track showSpinner = false;

  connectedCallback() {


   
  
  
 

    this.slideIndex = this.startFrom;
    setTimeout(() => {

     this.arrayLength = this.array.length;
      this.showSlides(this.slideIndex);
    }, 1000);

  }
  plusSlides() {
    let n = 1;
    this.showSlides(this.slideIndex += n);
  }

  minusSlides() {
    let n = -1;
    this.showSlides(this.slideIndex += n);
  }
  currentSlide(n) {
    this.showSlides(this.slideIndex = n);
  }

  showSlides(n) {
    this.showSpinner = true;
    let i;
    let slides = this.template.querySelectorAll(".mySlides");
 

    if (n > slides.length) { this.slideIndex = 1 }
    if (n < 1) { this.slideIndex = slides.length }
    for (i = 0; i < slides.length; i++) {

      if (slides[i] != undefined) {
        slides[i].style.display = "none";
      }
    }
    //   for (i = 0; i < dots.length; i++) {
    //     dots[i].className = dots[i].className.replace(" active", "");
    //   }
    slides[this.slideIndex - 1].style.display = "flex";
    //   dots[this.slideIndex-1].className += " active";
    this.showSpinner = false;
  }

  closeModal(){

    switch (this.parentScreenName) {
      case "Events":
      document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:true,currentStep:"events"}}));
      break;
      case "News And Announcement":
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:true,currentStep:"news-and-announcements"}}));
      break;
      case "Activities":
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:true,currentStep:"activities"}}));
      break;
      case "Dashboard":
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:true,currentStep:"Dashboard"}}));
        break;
    }
    this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
   
}

}