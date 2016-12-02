/**
 * =================说明==================
 * propsync：vue组件的混合对象，主要用于组件编写时混入调用。
 *
 * 【主要功能】
 * 1、实现了在组件内自动创建所有prop对应的data属性，方便组件内修改prop使用。解决了vue2.0中不允许组件内直接修改prop的设计。
 * 2、实现了组件外修改组件prop，组件内自动同步修改到data属性。
 * 3、实现了组件内修改了data属性（由prop创建的），自动向组件外发出事件通知有内部prop修改。由组件外决定是否要将修改同步到组件外
 *
 * 【使用方法】
 * 1、编写组件：在选项对象中增加 mixins:[propsync]即可，无需其他修改
 * 2、调用组件：在调用组件的templat处，增加一个事件监听 onPropsChange（可修改）,当组件内修改了props时会调用此函数，返回 修改prop名称，修改后值，修改前值
 *
 * 调用组件例：
 * <mycomponent :prop1="xxx" :prop2="xxx" @onPropsChange="change"></mycomponent>
 *
 * {
 *   methods:{
 *     change:function(propName,newVal,oldVal){
 *       this[propName]=newVal;
 *       console.log("组件mycomponent的" +propName+ "属性由" +oldVal+ "修改为了" +newVal);
 *     }
 *   }
 * }
 *
 * 【可配置忽略】
 * 默认情况下，调用了本mixin的组件，会实现组件定义的所有的props，创建对应data变量，绑定双向watch。
 * 若希望某个props不进行绑定（如仅纯展示型props），则可在那个props中增加propsync:false(可配置)来忽略，默认所有props均为true
 * 例：
 * props:{
 *   xxx:{
 *     type: String,
 *     default: "xxx",
 *     propsync: false//增加此props的属性，则本mixin会忽略xxx
 *   }
 * }
 */
/**
 * 【配置】
 * 当在组件内部修改了prop属性，对外emit发出的事件名称
 */
const emitPropsChangeName = "onPropsChange";
/**
 * 【配置】
 * 可在组件属性中定义当前props是否参加本mixin实现双向绑定。
 */
const isEnableName = "propsync";
/**
 * 【配置】
 * 根据prop的名称生成对应的data属性名，可自行修改生成后的名称。
 * 默认为在prop属性名前面增加"p_"，即若prop中有字段名为"active"，则自动生成名为"p_active"的data字段
 *
 * @param {string} propName 组件prop字段名称
 * @returns {string} 返回生成的data字段名
 */
function getDataName(propName) {
    //注意：映射后名称不能以 $ 或 _ 开头，会被vue认定为内部属性！！
    return "p_" + propName;
}
export default {
    //修改data，自动生成props对应的data字段
    data: function () {
        var data = {};
        var that = this;
        /** 所有组件定义的props名称数组 */
        var propsKeys = Object.keys((that.$options.props) || {});
        propsKeys.forEach(function (prop, i) {
            var dataName = getDataName(prop);
            var isEnable = that.$options.props[prop][isEnableName];
            isEnable = (typeof isEnable === "boolean") ? isEnable : true;
            if (!isEnable)
                return;
            //若使用mixins方法导入本代码，则本函数会 先于 组件内data函数执行！
            data[dataName] = that[prop];
        });
        return data;
    },
    created: function () {
        var that = this;
        /** 所有 取消props的watch监听函数 的数组 */
        var unwatchPropsFnArr = [];
        /** 所有 取消data的watch监听函数 的数组 */
        var unwatchDataFnArr = [];
        /** 所有组件定义的props名称数组 */
        var propsKeys = Object.keys((that.$options.props) || {});
        propsKeys.forEach(function (prop, i) {
            var dataName = getDataName(prop);
            var isEnable = that.$options.props[prop][isEnableName];
            isEnable = (typeof isEnable === "boolean") ? isEnable : true;
            if (!isEnable)
                return;
            //监听所有props属性
            var propsFn = that.$watch(prop, function (newVal, oldVal) {
                that[dataName] = newVal; //将组件外变更的prop同步到组件内的p_prop变量中
            }, {});
            unwatchPropsFnArr.push(propsFn);
            //[监听所有属性映射到组件内的变量]
            var dataFn = that.$watch(dataName, function (newVal, oldVal) {
                that.$emit(emitPropsChangeName, prop, newVal, oldVal); //将组件内p_prop通知给组件外(调用方)
            }, {});
            unwatchDataFnArr.push(dataFn);
        });
    },
    destroyed: function () {
        
    }
};

//博客园 @xxcanghai @小小沧海 