angular.module('forceInput', [])
.directive('forceInput', function($compile){

    var get_template = function(ftype){

        var tempalte = '';
        var string_based_types = {
            string : 'text',
            encryptedstring : 'password',
            email : 'email',
            url : 'url',
            phone : 'tel',
            double : 'number',
            integer : 'number',
            currency : 'number',
            percent : 'number',
            datetime : 'datetime-local',
            time : 'time'
        }

        if (typeof string_based_types[ftype] != 'undefined'){
            template = 
                "<div ng-show='field.autoNumber == false' class='form-group'>\n" +
                    "<label class='col-sm-4 control-label'>{{field.label}}</label>\n" +
                    "<div class='col-sm-8'>\n" +
                        "<input ng-show='field.updateable' type='" + string_based_types[ftype] + "' class='form-control' ng-model='record[field.name]' ng-required='!field.nillable' />\n" +
                        "<p ng-show='!field.updateable' class='form-control-static'>{{record[field.name]}}</p>\n" +
                    "</div>\n" +
                "</div>\n";
            return template;
        }

        if (ftype == 'id'){
            template =
                "<div class='form-group'>\n" +
                    "<label class='col-sm-4 control-label'>{{field.label}}</label>\n" +
                    "<div class='col-sm-8'>\n" +
                        "<p class='form-control-static'>{{record[field.name]}}</p>\n" +
                    "</div>\n" +
                "</div>\n";
            return template;
        } else if (ftype == 'textarea'){
            template = 
                "<div class='form-group'>\n" +
                    "<label class='col-sm-4 control-label'>{{field.label}}</label>\n" +
                    "<div class='col-sm-8'>\n" +
                        "<textarea ng-show='field.updateable' row='3' class='form-control' ng-model='record[field.name]' ng-required='!field.nillable' />\n" +
                        "<p ng-show='!field.updateable' class='form-control-static'>{{record[field.name]}}</p>\n" +
                    "</div>\n" +
                "</div>\n";
            return template;
        } else if (ftype == 'boolean'){
            template = 
                "<div class='form-group'>\n" +
                    "<label class='col-sm-4 control-label'>{{field.label}}</label>\n" +
                    "<div class='col-sm-8'>\n" +
                        "<div ng-show='field.updateable' class='checkbox'>\n" +
                            "<label>\n" +
                                "<input type='checkbox' ng-model='record[field.name]' />&nbsp;\n" +
                            "</label>\n" +
                        "</div>\n" + 
                        "<p ng-show='!field.updateable' class='form-control-static'>{{record[field.name]}}</p>\n" +
                    "</div>\n" +
                "</div>\n";
            return template;
        } else if (ftype == 'date'){
            template = 
                "<div class='form-group'>\n" +
                    "<label class='col-sm-4 control-label'>{{field.label}}</label>\n" +
                    "<div class='col-sm-8'>\n" +
                        "<input ng-show='field.updateable' type='date' class='form-control' ng-model='record[field.name]' ng-required='!field.nillable' placeholder='yyyy/MM/dd' />\n" +
                        "<p ng-show='!field.updateable' class='form-control-static'>{{record[field.name]}}</p>\n" +
                    "</div>\n" +
                "</div>\n";
            return template;
        } else if (ftype == 'picklist'){
            template = 
                "<div class='form-group'>\n" +
                    "<label class='col-sm-4 control-label'>{{field.label}}</label>\n" +
                    "<div class='col-sm-8'>\n" +
                        "<select ng-show='field.updateable' class='form-control' ng-model='record[field.name]'>\n" +
                            "<option ng-repeat='picklistValue in field.picklistValues' value='{{picklistValue.value}}'>{{picklistValue.label}}</option>\n" +
                        "</select>\n" +
                        "<p ng-show='!field.updateable' class='form-control-static'>{{record[field.name]}}</p>\n" +
                    "</div>\n" +
                "</div>\n";
            return template;
        } else if (ftype == 'multipicklist'){
            template = 
                "<div class='form-group'>\n" +
                    "<label class='col-sm-4 control-label'>{{field.label}}</label>\n" +
                    "<div class='col-sm-8'>\n" +
                        "<select ng-show='field.updateable' multiple='multiple' class='form-control' ng-model='record[field.name]'>\n" +
                            "<option ng-repeat='picklistValue in field.picklistValues' value='{{picklistValue.value}}'>{{picklistValue.label}}</option>\n" +
                        "</select>\n" +
                        "<p ng-show='!field.updateable' class='form-control-static'>{{record[field.name]}}</p>\n" +
                    "</div>\n" +
                "</div>\n";
            return template;
        }
    }

    var linker = function(scope, element, attr){
        element.html(get_template(scope.field.type)).show();
        $compile(element.contents())(scope);
    }

    return {
        restrict: 'E',
        link: linker,
        scope: {
            field: '=',
            record: '='
        }
    }
});
