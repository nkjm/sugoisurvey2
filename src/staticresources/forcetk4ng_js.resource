angular.module('forcetk4ng', [])
.service('force', function($http, $q){
    this.apiVersion = 'v32.0';

    var headers = {}; 
    headers['Content-Type'] = 'application/json';

    this.setAccessToken = function(accessToken){
        this.accessToken = accessToken;
        headers['Authorization'] = 'OAuth ' + this.accessToken;
    }

    this.setApiVersion = function(apiVersion){
        this.apiVersion = apiVersion;
    }

    this.setNamespace = function(namespace){
        headers['Sforce-Call-Options'] = 'client=' + this.accessToken + ', defaultNamespace=' + namespace;
    }

    this.ajax = function(path, method, responseType){
        var d = $q.defer();

        $http({
            method: method || 'GET',
            url: 'https://' + location.hostname + path,
            headers: headers,
            responseType: responseType || 'text/json'
        })
        .success(function(data, status, headers, config){
            d.resolve(data);
        })
        .error(function(data, status, headers, config){
            d.reject(data);
        });

        return d.promise;   
    }

    this.query = function(soql){
        console.log(headers);
        var d = $q.defer();

        $http({
            method: 'GET',
            url: 'https://' + location.hostname + '/services/data/' + this.apiVersion + '/query/?q=' + encodeURI(soql),
            headers: headers,
            responseType: 'text/json'
        })
        .success(function(data, status, headers, config){
            d.resolve(data.records);
        })
        .error(function(data, status, headers, config){
            d.reject(data);
        });

        return d.promise;
    }

    this.retrieve = function(objectType, id, fields){
        var d = $q.defer();

        if (fields != null && fields.length > 0){
            var fieldsInCsv = '';
            angular.forEach(fields, function(field, key){
                fieldsInCsv += field + ',';
            })
            fieldInCsv = fieldInCsv.slice(0, fieldInCsv.length - 1);
            fieldsInCsvInUri = fieldsInCsv ? '?fields=' + fieldsInCsv : '';
        } else {
            fieldsInCsvInUri = '';
        }

        $http({
            method: 'GET',
            url: 'https://' + location.hostname + '/services/data/' + this.apiVersion + '/sobjects/' + objectType + '/' + id + fieldsInCsvInUri,
            headers: headers,
            responseType: 'text/json'
        })
        .success(function(data, status, headers, config){
            d.resolve(data);
        })
        .error(function(data, status, headers, config){
            d.reject(data);
        });

        return d.promise;
    }

    this.create = function(objectType, origRecord){
        var d = $q.defer();

        var record = angular.copy(origRecord);

        // Delete unnecessary fields
        for (var f in record){
            if (f.substring(f.length - 3, f.length) == '__r'){
                delete record[f];
            }
            if (f == 'attributes'){
                delete record[f];
            }
            if (f == '$$hashKey'){
                delete record[f];
            }
        }

        var apiVersion = this.apiVersion;

        this.describe(objectType)
        .then(
            function(desc){
                // Remove fields which are not createable
                angular.forEach(desc.fields, function(f, key){
                    if (!f.createable){
                        delete record[f.name];
                    }
                })
                $http({
                    method: 'POST',
                    url: 'https://' + location.hostname + '/services/data/' + apiVersion + '/sobjects/' + objectType + '/',
                    headers: headers,
                    responseType: 'text/json',
                    data: record
                })
                .success(function(data, status, headers, config){
                    d.resolve(data);
                })
                .error(function(data, status, headers, config){
                    d.reject(data);
                });
            },
            function(error){
                d.reject(error);
            }
        );

        return d.promise;
    }

    this.update = function(objectType, origRecord){
        var d = $q.defer();

        var record = angular.copy(origRecord);

        // Delete unnecessary fields
        for (var f in record){
            if (f.substring(f.length - 3, f.length) == '__r'){
                delete record[f];
            }
            if (f == 'attributes'){
                delete record[f];
            }
            if (f == '$$hashKey'){
                delete record[f];
            }
        }

        var apiVersion = this.apiVersion;
        var params = {};
        params['_HttpMethod'] = 'PATCH';

        this.describe(objectType)
        .then(
            function(desc){
                // Remove fields which are not updateable
                angular.forEach(desc.fields, function(f, key){
                    if (!f.updateable){
                        delete record[f.name];
                    }
                })
                $http({
                    method: 'PATCH',
                    url: 'https://' + location.hostname + '/services/data/' + apiVersion + '/sobjects/' + objectType + '/' + origRecord.Id,
                    headers: headers,
                    responseType: 'text/json',
                    data: record,
                    params: params
                })
                .success(function(data, status, headers, config){
                    d.resolve(data);
                })
                .error(function(data, status, headers, config){
                    d.reject(data);
                });
            },
            function(error){
                d.reject(error);
            }
        );

        return d.promise;
    }

    this.upsert = function(objectType, extIdField, extId, origRecord){
        var d = $q.defer();

        var record = angular.copy(origRecord);

        // Delete unnecessary fields
        for (var f in record){
            if (f.substring(f.length - 3, f.length) == '__r'){
                delete record[f];
            }
            if (f == 'attributes'){
                delete record[f];
            }
            if (f == '$$hashKey'){
                delete record[f];
            }
        }

        var apiVersion = this.apiVersion;
        var params = {};
        params['_HttpMethod'] = 'PATCH';

        this.describe(objectType)
        .then(
            function(desc){
                // Remove fields which are not createable or updateable
                angular.forEach(desc.fields, function(f, key){
                    if (!f.createable || !f.updateable){
                        delete record[f.name];
                    }
                })
                $http({
                    method: 'PATCH',
                    url: 'https://' + location.hostname + '/services/data/' + apiVersion + '/sobjects/' + objectType + '/' + extIdField + '/' + extId,
                    headers: headers,
                    responseType: 'text/json',
                    data: record,
                    params: params
                })
                .success(function(data, status, headers, config){
                    d.resolve(data);
                })
                .error(function(data, status, headers, config){
                    d.reject(data);
                });
            },
            function(error){
                d.reject(error);
            }
        );

        return d.promise;
    }

    this.delete = function(objectType, id){
        var d = $q.defer();

        $http({
            method: 'DELETE',
            url: 'https://' + location.hostname + '/services/data/' + this.apiVersion + '/sobjects/' + objectType + '/' + id,
            headers: headers,
            responseType: 'text/json'
        })
        .success(function(data, status, headers, config){
            d.resolve(data);
        })
        .error(function(data, status, headers, config){
            d.reject(data);
        });

        return d.promise;
    }

    this.describe = function(objectType){
        var d = $q.defer();

        $http({
            method: 'GET',
            url: 'https://' + location.hostname + '/services/data/' + this.apiVersion + '/sobjects/' + objectType + '/describe/',
            headers: headers,
            responseType: 'text/json'
        })
        .success(function(data, status, headers, config){
            d.resolve(data);
        })
        .error(function(data, status, headers, config){
            d.reject(data);
        });

        return d.promise;
    }
});
