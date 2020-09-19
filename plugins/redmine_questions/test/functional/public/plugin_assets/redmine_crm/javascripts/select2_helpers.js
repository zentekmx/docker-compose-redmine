var oldToggleFilter = window.toggleFilter;

window.toggleFilter = function (field) {
    oldToggleFilter(field);
    return transform_to_select2(field);
};

function formatStateWithAvatar(opt) {
    return $('<span>' + opt.avatar + '&nbsp;' + opt.text + '</span>');
};

var select2Filters = {};

function transform_to_select2(field) {
    field = field.replace('.', '_');
    var filter = select2Filters[field];
    if (filter !== undefined && $('#tr_' + field + ' .values .select2').size() == 0) {
        $('#tr_' + field + ' .toggle-multiselect').hide();
        $('#tr_' + field + ' .values .value').attr('multiple', 'multiple');
        $('#tr_' + field + ' .values .value').select2({
            ajax: {
                url: filter['url'],
                dataType: 'json',
                delay: 250,
                data: function (params) {
                    return {q: params.term};
                },
                processResults: function (data, params) {
                    return {results: data};
                },
                cache: true
            },
            placeholder: ' ',
            minimumInputLength: filter['minimumInputLength'],
            width: filter['width'],
            templateResult: filter['formatState']
        });
    }
};