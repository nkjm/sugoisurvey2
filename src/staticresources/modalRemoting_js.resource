angular.module('modalRemoting', ['ui.bootstrap', 'forceInput', 'template/modalRemoting.html'])
.factory('remoting', function($modal){
    return {
        result : null,
        status : null,
        alerts : [],
        progress : 0,
        init : function(showModal){
            if (showModal == null || showModal == true){
                $modal.open({
                    templateUrl: "template/modalRemoting/inProgress.html",
                    backdrop: "static",
                    controller: "inProgressCtl"
                });
            }
            this.result = 'primary';
            this.status = null;
            this.alerts = [];
            this.progress = 1;
        },
        confirm : function(title, callback){
            var modalInstance = $modal.open({
                templateUrl: "template/modalRemoting/confirm.html",
                backdrop: "static",
                controller: "confirmCtl",
                resolve: {
                    title: function(){
                        return title;
                    }
                }
            });
            modalInstance.result.then(
                function(){
                    callback();
                }
            );
        },
        form : function(title, fields, callback){
            var modalInstance = $modal.open({
                templateUrl: "template/modalRemoting/form.html",
                controller: "formCtl",
                resolve: {
                    title: function(){
                        return title;
                    },
                    fields: function(){
                        return fields;
                    }
                }
            });

            modalInstance.result.then(
                function(record){
                    callback(record);
                }
            );
        },
        success : function(message){
            this.result = 'success';
            if (message != null){
                this.status = message;
            }
        },
        error : function(event){
            this.result = 'danger';
            if (event != null){
                if (typeof event == 'string'){
                    if (event != null && event != ''){
                        this.alerts.push(event);
                    }
                } else if (typeof event == 'object'){
                    if (Array.isArray(event)){
                        var messages = [];
                        angular.forEach(event, function(e, key){
                            if (e.message != null && e.message != ''){
                                messages.push(e.message);
                            }
                        });
                        this.alerts = this.alerts.concat(messages);
                    } else {
                        if (event.message != null && event.message != ''){
                            this.alerts.push(event.message);
                        }
                    }
                }
                
            }
        }
    }
})
.controller('inProgressCtl', function($scope, $modalInstance, remoting){
    $scope.remoting = remoting;
})
.controller('confirmCtl', function($scope, $modalInstance, title){
    $scope.title = title;
})
.controller('formCtl', function($scope, $modalInstance, title, fields){
    $scope.title = title;
    $scope.fields = fields;
    $scope.record = {};
});

angular.module('template/modalRemoting.html', []).run(["$templateCache", function($templateCache){
    $templateCache.put("template/modalRemoting/inProgress.html",
        "<div class=\"modal-header\">\n" +
            "<h3>\n" +
                "<span ng-show=\"remoting.result != 'danger' && remoting.progress < 100\">処理中</span>\n" + 
                "<span ng-show=\"remoting.result != 'danger' && remoting.progress == 100\">完了</span>\n" +
                "<span ng-show=\"remoting.result == 'danger'\">エラー</span>\n" +
            "</h3>\n" + 
        "</div>\n" +
        "<div class=\"modal-body\">\n" +
            "<progressbar ng-hide=\"remoting.result == 'danger'\" ng-class=\"(remoting.progress < 100) ? 'progress-striped active' : 'progress-striped'\" value=\"remoting.progress\" type=\"primary\"></progressbar>\n" +
            "<div ng-hide=\"remoting.result == 'danger'\">{{remoting.status}}</div>\n" +
            "<div ng-repeat=\"alert in remoting.alerts\" class=\"alert alert-danger\">{{alert}}</div>\n" +
        "</div>\n" +
        "<div class=\"modal-footer\" ng-show=\"remoting.progress == 100 || remoting.result == 'danger'\">\n" + 
            "<button type=\"button\" class=\"btn btn-default\" ng-click=\"$close()\">閉じる</button>\n" +
        "</div>");

    $templateCache.put("template/modalRemoting/confirm.html",
        "<div class=\"modal-header\">\n" +
            "<h3>{{title}}</h3>\n" + 
        "</div>\n" +
        "<div class=\"modal-body\">よろしいですか？</div>\n" +
        "<div class=\"modal-footer\">\n" +
            "<button type=\"button\" class=\"btn btn-default\" ng-click=\"$dismiss()\">閉じる</button>\n" +
            "<button type=\"button\" class=\"btn btn-danger\" ng-click=\"$close()\">実行</button>\n" +
        "</div>");

    $templateCache.put("template/modalRemoting/form.html",
        "<div class=\"modal-header\">\n" + 
            "<h3>{{title}}</h3>\n" + 
        "</div>\n" + 
        "<div class=\"modal-body\">\n" + 
            "<form class=\"form-horizontal\" role=\"form\">\n" + 
                "<force-input ng-repeat=\"field in fields\" field=\"field\" record=\"record\"></force-input>\n" + 
            "</form>\n" + 
        "</div>\n" + 
        "<div class=\"modal-footer\">\n" + 
            "<button type=\"button\" class=\"btn btn-default\" ng-click=\"$dismiss()\">キャンセル</button>\n" + 
            "<button type=\"button\" class=\"btn btn-primary\" ng-click=\"$close(record)\">保存</button>\n" + 
        "</div>");
}]);