angular.module('sugoiQuestion', ['ngSanitize'])
.directive('sugoiQuestion', function($compile, $sanitize){

    var get_template = function(csq, guest, csas){
        var template = 
            "<div class='panel panel-default'>\n" +
                "<div class='panel-heading'>\n" +
                    $sanitize(csq.sugoisurvey5__Question__c) + 
                    " &nbsp;<span ng-show='csq.sugoisurvey5__Required__c' class='badge'>必須</span>\n" +
                "</div>\n";

        if (csq.sugoisurvey5__Survey_Type__c == 'checkbox'){
            template += 
                "<div class='list-group list-group'>\n";
            angular.forEach(csq.sugoisurvey5__Custom_Survey_Option__r, function(cso, key){
                template += 
                    "<a class='list-group-item' ng-click='csas." + cso.Id + ".selected = !csas." + cso.Id + ".selected' ng-init='csas." + cso.Id + ".selected = false; csas." + cso.Id + ".type=\"checkbox\"'>\n" +
                        "<span ng-show='csas." + cso.Id + ".selected' class='glyphicon glyphicon-check'></span>" +
                        "<span ng-show='!csas." + cso.Id + ".selected' class='glyphicon glyphicon-unchecked'></span>" +
                        "&nbsp;" + $sanitize(cso.sugoisurvey5__Option__c) + 
                    "</a>\n";
                if (cso.sugoisurvey5__Enable_Free_Form__c){
                    template +=
                    "<div class='list-group-item' ng-show='csas." + cso.Id + ".selected == true'>\n" +
                        "<textarea ng-model='csas." + cso.Id + ".value' class='form-control' rows='4' />\n" +
                    "</div>\n";
                }
            })
            template += 
                "</div>\n";
        } else if (csq.sugoisurvey5__Survey_Type__c  == 'radio'){
            template += 
                "<div class='list-group list-group'>\n";
            angular.forEach(csq.sugoisurvey5__Custom_Survey_Option__r, function(cso, key){
                template += 
                    "<a class='list-group-item' ng-click='check_radio(\"" + cso.Id + "\")' ng-init='csas." + cso.Id + ".selected = false; csas." + cso.Id + ".type=\"radio\"'>\n" +
                        "<span ng-show='csas." + cso.Id + ".selected' class='glyphicon glyphicon-check'></span>" +
                        "<span ng-show='!csas." + cso.Id + ".selected' class='glyphicon glyphicon-unchecked'></span>" +
                        "&nbsp;" + $sanitize(cso.sugoisurvey5__Option__c) + 
                    "</a>\n";
                if (cso.sugoisurvey5__Enable_Free_Form__c){
                    template +=
                    "<div class='list-group-item' ng-show='csas." + cso.Id + ".selected == true'>\n" +
                        "<textarea ng-model='csas." + cso.Id + ".value' class='form-control' rows='4' />\n" +
                    "</div>\n";
                }
            })
            template += 
                "</div>\n";
        } else if (csq.sugoisurvey5__Survey_Type__c  == 'free'){
            template +=
                "<div class='panel-body'>\n" +
                    "<div class='form-group'>\n" + 
                        "<textarea ng-model='csas." + csq.sugoisurvey5__Custom_Survey_Option__r[0].Id + ".value' ng-init='csas." + csq.sugoisurvey5__Custom_Survey_Option__r[0].Id + ".type = \"free\"' class='form-control' rows='4' placeholder='255文字まで' />\n" +
                    "</div>\n" +
                "</div>\n";
        } else if (csq.sugoisurvey5__Survey_Type__c  == 'rating'){
            template +=
                "<div class='panel-body'>\n" +
                    "<div class='form-group'>\n" + 
                        "<span class='glyphicon glyphicon-thumbs-down'></span>&nbsp\n" + 
                            "<div class='btn-group'>\n";

            angular.forEach(csq.sugoisurvey5__Custom_Survey_Option__r, function(cso, key){
                template += 
                                "<button ng-click='check_radio(\"" + cso.Id + "\")' ng-init='csas." + cso.Id + ".selected = false; csas." + cso.Id + ".type=\"rating\"' csotype='button' class='btn' ng-class='(csas." + cso.Id + ".selected == true) ? \"btn-danger active\" : \"btn-default\"'>" + cso.sugoisurvey5__Option_Of_Number__c + "</button>\n";
            });
            template += 
                            "</div>\n" + 
                        "&nbsp;<span class='glyphicon glyphicon-thumbs-up'></span>\n" + 
                    "</div>\n" +
                "</div>\n";
        } else if (csq.sugoisurvey5__Survey_Type__c  == 'number'){
            template +=
                "<div class='panel-body'>\n" + 
                    "<div class='form-group'>\n" + 
                        "<input ng-model='csas." + csq.sugoisurvey5__Custom_Survey_Option__r[0].Id + ".value' ng-init='csas." + csq.sugoisurvey5__Custom_Survey_Option__r[0].Id + ".type = \"number\"' type='number' class='form-control' />\n" +
                    "</div>\n" +
                "</div>\n";
        } else if (csq.sugoisurvey5__Survey_Type__c  == 'guest'){
            template += "<div class='panel-body'>\n";
            angular.forEach(csq.sugoisurvey5__Custom_Survey_Option__r, function(cso, key){
                var guest_field_label;
                angular.forEach(guest.fields, function(guest_field, key){
                    if (guest_field.name == cso.sugoisurvey5__Option__c){
                        guest_field_label = guest_field.label;
                    }
                });
                template +=
                        "<div class='form-group'>\n" + 
                            "<label>\n" + 
                                guest_field_label + 
                                " &nbsp;<span ng-show='" + cso.sugoisurvey5__Required__c + "' class='badge'>必須</span>\n" +
                            "</label>\n" + 
                            "<input ng-model='csas." + cso.Id + ".value' ng-init='csas." + cso.Id + ".type = \"guest\"' class='form-control' type='text' />\n" +
                        "</div>\n";
            })
            template += "</div>\n";
        }

        template += "</div>\n";
        return template;
    }

    var linker = function(scope, element, attr){
        element.html(get_template(scope.csq, scope.guest, scope.csas)).show();
        $compile(element.contents())(scope);
    }

    return {
        replace: true,
        restrict: 'E',
        link: linker,
        scope: {
            csq: '=',
            guest: '=',
            csas: '='
        },
        controller: function($scope){
            $scope.check_radio = function(cso_id){
                angular.forEach($scope.csq.sugoisurvey5__Custom_Survey_Option__r, function(cso, key){
                    if (cso_id == cso.Id){
                        $scope.csas[cso.Id].selected = true;
                    } else {
                        $scope.csas[cso.Id].selected = false;
                    }
                })
            }
        }
    }
});
